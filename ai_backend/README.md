# Dream Logs local image-generation experiment

This is a **local proof of concept**, not yet connected to Flutter, Firebase, Dream Cast, or video generation. It uses Stable Diffusion 1.5 via Hugging Face Diffusers. Model downloads require several GB of free disk space and may require accepting model terms/authentication.

From the project root in PowerShell, with the existing Python 3.11 virtual environment active and CUDA-enabled PyTorch installed:

```powershell
python -m pip install -r ai_backend/requirements.txt
python ai_backend/generate_local.py --prompt "A cinematic dream of flying above a glowing city at night"
```

Output: `ai_backend/outputs/dream.png`. The first run downloads model weights. On a 4 GB GTX 1650 Ti, generation can be slow and may run out of memory. Close GPU-heavy programs first. If the GPU runs out of memory, try `--steps 12` or restart the process.

**Security:** Never commit API keys, private reference photos, or generated images. Do not expose this local script as a public API. Before connecting Dream Cast, enforce per-photo consent and authorized backend access.

Next milestones: structured storyboards, authenticated Firebase jobs, reference-aware generation, cloud GPU deployment, and a separate video provider.
