"""Local Firestore Dream Story worker. Uses Firebase Admin credentials on this PC only."""
import argparse
import os
import time
from pathlib import Path

import firebase_admin
from firebase_admin import credentials, firestore, storage
from PIL import Image
import numpy as np
import torch
from diffusers import StableDiffusionPipeline


def make_pipeline():
    print("Loading Stable Diffusion (FP32 + CPU offload)...", flush=True)
    pipe = StableDiffusionPipeline.from_pretrained(
        "stable-diffusion-v1-5/stable-diffusion-v1-5",
        torch_dtype=torch.float32,
        safety_checker=None,
        requires_safety_checker=False,
    )
    pipe.enable_attention_slicing()
    pipe.enable_vae_slicing()
    pipe.enable_model_cpu_offload()
    return pipe


def process(doc, db, bucket, pipe):
    ref = doc.reference
    data = doc.to_dict()
    if data.get("status") != "queued" or data.get("type") != "story":
        return
    # Transactional claim avoids duplicate work if multiple workers are running.
    transaction = db.transaction()

    @firestore.transactional
    def claim(tx):
        fresh = ref.get(transaction=tx)
        if not fresh.exists or fresh.to_dict().get("status") != "queued":
            return False
        tx.update(ref, {"status": "processing", "startedAt": firestore.SERVER_TIMESTAMP})
        return True

    if not claim(transaction):
        return
    print(f"Generating dream {doc.id}...", flush=True)
    try:
        prompt = data.get("description", "").strip()[:1000]
        if not prompt:
            raise ValueError("Dream description is empty")
        style = data.get("style", "Cinematic")
        text = f"{style} dream scene, {prompt}, atmospheric, detailed, beautiful composition"
        image = pipe(
            prompt=text,
            negative_prompt="blurry, distorted, watermark, text, low quality",
            width=512,
            height=512,
            num_inference_steps=12,
            guidance_scale=7,
        ).images[0]
        pixels = np.asarray(image)
        if pixels.max() == 0 or pixels.std() < 1:
            raise RuntimeError("Generated image was blank")
        output = Path("ai_backend/outputs") / f"{doc.id}.png"
        output.parent.mkdir(parents=True, exist_ok=True)
        image.save(output)
        owner = data["ownerUid"]
        blob = bucket.blob(f"dreams/{owner}/{doc.id}/scene_1.png")
        blob.upload_from_filename(str(output), content_type="image/png")
        ref.update({
            "status": "completed",
            "scenes": [{"storagePath": blob.name, "caption": prompt[:200]}],
            "completedAt": firestore.SERVER_TIMESTAMP,
        })
        print(f"Completed {doc.id}", flush=True)
    except Exception as exc:
        print(f"Failed {doc.id}: {exc}", flush=True)
        ref.update({"status": "failed", "error": str(exc)[:300], "completedAt": firestore.SERVER_TIMESTAMP})


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--credentials", required=True, help="Path to Firebase service account JSON; never commit it")
    parser.add_argument("--project", default="dream-logs")
    parser.add_argument("--bucket", default="dream-logs.firebasestorage.app")
    parser.add_argument("--interval", type=int, default=10)
    args = parser.parse_args()
    if not torch.cuda.is_available():
        raise RuntimeError("CUDA is not available")
    firebase_admin.initialize_app(
        credentials.Certificate(args.credentials),
        {"projectId": args.project, "storageBucket": args.bucket},
    )
    db = firestore.client()
    bucket = storage.bucket()
    pipe = make_pipeline()
    print("Worker running. Waiting for queued Dream Stories...", flush=True)
    while True:
        try:
            jobs = db.collection("dreams").where("status", "==", "queued").limit(10).stream()
            for doc in jobs:
                if doc.to_dict().get("type") == "story":
                    process(doc, db, bucket, pipe)
        except Exception as exc:
            print(f"Polling error: {exc}", flush=True)
        time.sleep(args.interval)


if __name__ == "__main__":
    main()
