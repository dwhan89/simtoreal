# Sim-to-real environment

Reproducible setup for the calibrated sensor-fusion project. Stack: **CARLA**
(simulator + Python client) for the sim side, **PyTorch** for the fusion
backbone and diffusion policy, **nuscenes-devkit** for the real-data half.
Packages are managed with **uv**.

## Two containers, not one

This repo's image is the **CARLA client + training code**. The **CARLA
simulator** — the actual Unreal-Engine server that renders scenes and streams
sensor data — is a separate, much larger image (`carlasim/carla` on Docker
Hub) that runs alongside it and needs its own GPU. The client in this image
connects to the simulator over CARLA's RPC API (default port 2000), it does
not embed it. Run the simulator headless with `-RenderOffScreen` on a cloud
box with no display.

## Files

- `../pyproject.toml` / `../uv.lock` — the dependency set (root of the repo,
  not this folder) and its resolved, pinned lockfile. `torch`/`torchvision`
  resolve from PyTorch's own cu126 index; everything else, `carla` included,
  resolves from PyPI.
- `Dockerfile` — the client/training image for cloud GPU instances. Built
  from the **repo root** so it can see `pyproject.toml`/`uv.lock`.
- `docker-compose.yml` — launches the CARLA simulator and this client image
  together for cloud deployment (see "Running on RunPod / Vast.ai" below).
- `../tests/smoke_test.py` — run this first on every fresh instance to catch
  setup problems fast. It checks torch's CUDA device and that the `carla`
  and `nuscenes` packages import; it does not attempt to connect to a running
  CARLA server.

## Local development (on a machine you own)

No conda needed — uv creates and manages its own virtualenv:

```bash
uv sync                        # from the repo root
uv run python tests/smoke_test.py
```

On local macOS there is no CARLA wheel for this platform, so `smoke_test.py`
skips that check — only torch (CPU/MPS) and nuscenes-devkit run locally.
Anything that actually talks to CARLA needs the Linux target (Docker/cloud),
either against a simulator running there or one reachable over the network.

## Memory

If a large batch
still runs short of memory, the two options are the usual ones: shrink the batch, or
watch for fragmentation with `PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True`.

## Running on RunPod / Vast.ai

1. Build and push the client image, from the **repo root**. Cloud GPU boxes
   are linux/amd64 — if building on Apple Silicon (arm64), pass
   `--platform linux/amd64` explicitly.
   ```bash
   docker buildx build --platform linux/amd64 \
     -f docker/Dockerfile -t <your-dockerhub-user>/simtoreal:latest --push .
   ```
2. Launch both containers with `docker/docker-compose.yml`, which wires
   `carlasim/carla` (headless: `./CarlaUE4.sh -RenderOffScreen`) and this
   client image on one network and points the client at the simulator's
   host:port (2000 by default):
   ```bash
   docker compose -f docker/docker-compose.yml up
   ```
   Set `CLIENT_IMAGE` to the tag you pushed in step 1 if it's not
   `simtoreal:latest`. Prefer to launch the two containers by hand instead?
   Just make sure the client can reach the simulator's host:port (2000 by
   default).
3. Pick a GPU with enough headroom for both the simulator and torch training —
   an RTX 4090 (24 GB) covers CARLA plus a modest fusion-model batch; split
   across two GPUs if training gets memory-hungry (`CARLA_GPU`/`CLIENT_GPU` in
   the compose file).
4. The compose file attaches a **persistent volume** at `/workspace/data` (not
   `/workspace` itself — that root holds the image's baked-in `.venv` and
   code, which an empty volume would otherwise shadow on first mount) so
   checkpoints and downloaded nuScenes/KITTI data survive a restart.
5. SSH in and verify:
   ```bash
   python smoke_test.py
   ```

*(No time to build an image? Start from any RunPod CUDA template, `pip install
uv`, then `uv sync` — but a prebuilt image is faster to respin. In that case a
persistent volume at plain `/workspace` is fine, since there's no baked venv
to shadow.)*

## Version note

`uv.lock` pins the exact resolved package set (linux/x86_64), so builds are
reproducible without relying on loose pins. If you need to bump a version,
edit `pyproject.toml` and run `uv lock` to regenerate the lockfile — don't
hand-edit `uv.lock`. Keep the CARLA client version and the CARLA simulator
image version in lockstep (`carla==0.9.16` here pairs with the
`carlasim/carla:0.9.16` server image) — a version mismatch between client and
server is a common source of silent RPC failures.
