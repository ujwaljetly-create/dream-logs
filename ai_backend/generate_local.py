"""Local, experimental Dream Logs image generation (4 GB NVIDIA GPU)."""
import argparse
from pathlib import Path

import torch
from diffusers import StableDiffusionPipeline


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--prompt", required=True)
    parser.add_argument("--output", default="ai_backend/outputs/dream.png")
    parser.add_argument("--steps", type=int, default=20)
    parser.add_argument("--model", default="stable-diffusion-v1-5/stable-diffusion-v1-5")
    args = parser.parse_args()

    if not torch.cuda.is_available():
        raise RuntimeError("CUDA GPU not detected. Check PyTorch CUDA installation.")

    pipeline = StableDiffusionPipeline.from_pretrained(
        args.model,
        torch_dtype=torch.float16,
        safety_checker=None,
        requires_safety_checker=False,
    )
    pipeline.enable_attention_slicing()
    pipeline.enable_vae_slicing()
    pipeline.enable_model_cpu_offload()

    image = pipeline(
        prompt=args.prompt,
        negative_prompt="blurry, low quality, distorted, watermark, text",
        width=512,
        height=512,
        num_inference_steps=args.steps,
        guidance_scale=7.0,
    ).images[0]

    destination = Path(args.output)
    destination.parent.mkdir(parents=True, exist_ok=True)
    image.save(destination)
    print(f"Saved image to {destination.resolve()}")


if __name__ == "__main__":
    main()
