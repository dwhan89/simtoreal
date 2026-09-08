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
  resolve from PyTorch's own cu130 index; everything else, `carla` included,
  resolves from PyPI.
- `Dockerfile` — the client/training image for cloud GPU instances. Built
  from the **repo root** so it can see `pyproject.toml`/`uv.lock`.
- `docker-compose.yml` — launches the CARLA simulator and this client image
  together on one Docker network. Works on any host with its own Docker
  daemon (e.g. local development). Does **not** work on RunPod as-is — see
  "Running on RunPod" below for why and what to do instead.
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

## Running on RunPod

RunPod pods are **single containers, not VMs** — there's no Docker daemon
inside a pod for `docker-compose.yml`'s nested `docker run` to talk to, so
the compose file does not apply here. Deploy the simulator and the client as
**two separate pods** instead, connected over the network:

1. Build and push the client image, from the **repo root**. Cloud GPU boxes
   are linux/amd64 — if building on Apple Silicon (arm64), pass
   `--platform linux/amd64` explicitly.

   ```bash
   docker buildx build --platform linux/amd64 \
     -f docker/Dockerfile -t <your-dockerhub-user>/simtoreal:latest --push .
   ```

2. **Simulator pod**: image `carlasim/carla:0.9.16`, container start command
   `./CarlaUE4.sh -RenderOffScreen`. Expose TCP port 2000-2002 so the client
   pod can reach it, and note the actual public host:port RunPod assigns
   (its proxy may remap the port) from the pod's Connect tab.
3. **Client pod**: image `<your-dockerhub-user>/simtoreal:latest`. Override
   the container start command to `sleep infinity` — the image's default
   `CMD` (`/bin/bash`) exits immediately without a TTY, which leaves nothing
   for RunPod's SSH proxy to attach to. Attach a **persistent volume** at
   `/workspace/data` (not `/workspace` itself — that root holds the image's
   baked-in `.venv` and code, which an empty volume would otherwise shadow
   on first mount) for checkpoints and downloaded nuScenes/KITTI data.
4. Point the client at the simulator over the network — set
   `CARLA_HOST`/`CARLA_PORT` to the simulator pod's address from step 2
   (this replaces the compose file's internal `carla-sim` network alias,
   which only exists when both containers share one Docker network).
5. Pick GPUs and disk sizes with headroom for both the simulator and torch
   training. The fusion backbone and diffusion policy aren't implemented
   yet, so there's no measured batch size or memory footprint to size
   against — size conservatively and revisit once real training code
   exists. RunPod separates ephemeral **container disk** from persistent
   **volume disk**; the volume only needs to hold whatever dataset subset
   you're actually downloading plus checkpoints.
6. SSH into the client pod (RunPod's Connect tab gives you the command) and
   verify:

   ```bash
   python smoke_test.py
   ```

## Version note

`uv.lock` pins the exact resolved package set (linux/x86_64), so builds are
reproducible without relying on loose pins. If you need to bump a version,
edit `pyproject.toml` and run `uv lock` to regenerate the lockfile — don't
hand-edit `uv.lock`. Keep the CARLA client version and the CARLA simulator
image version in lockstep (`carla==0.9.16` here pairs with the
`carlasim/carla:0.9.16` server image) — a version mismatch between client and
server is a common source of silent RPC failures.
