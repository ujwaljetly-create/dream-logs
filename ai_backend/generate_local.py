"""Local Dream Logs image generation for memory-constrained NVIDIA GPUs."""
import argparse
from pathlib import Path

import numpy as np
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

    print("Loading Stable Diffusion with float32 VAE for numerical stability...")
    pipeline = StableDiffusionPipeline.from_pretrained(
        args.model,
        torch_dtype=torch.float16,
        safety_checker=None,
        requires_safety_checker=False,
    )
    # VAE decoding in fp16 can produce NaNs / black images on some GPUs.
    pipeline.vae.to(dtype=torch.float16)
    # Keep VAE weights and incoming latents at the same precision.
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
        output_type="pil",
    ).images[0]

    pixels = np.asarray(image)
    if pixels.max() == 0 or pixels.std() < 1:
        raise RuntimeError(
            "Generated image is blank. The model may have produced NaNs or "
            "run out of usable GPU memory. Try the --full-precision option."
        )

    destination = Path(args.output)
    destination.parent.mkdir(parents=True, exist_ok=True)
    image.save(destination)
    print(f"Saved image to {destination.resolve()}")


if __name__ == "__main__":
    main()
