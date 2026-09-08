# =============================================================================
#  Sim-to-real project image — CARLA client + PyTorch stack (BEVFusion-style
#  fusion backbone, diffusion policy). Base: CUDA + cuDNN, matching the
#  torch==2.13.0 CUDA wheel pulled from PyTorch's own index.
#
#  Two CUDA variants are published, so a RunPod host can be picked by whichever
#  driver it has. BASE_IMAGE and UV_LOCKFILE must move together — each lockfile
#  pins torch wheels from one specific CUDA index:
#      CUDA 13.0 (default): nvidia/cuda:13.0.3-... + uv.lock       (cu130)
#      CUDA 12.6:           nvidia/cuda:12.6.3-... + uv-cu126.lock (cu126)
#  Regenerate a secondary lockfile with scripts/lock-cuda-variant.sh.
#
#  This image holds the CARLA *client* and the training code only. The CARLA
#  *simulator* (the Unreal-Engine server this client talks to over RPC) is its
#  own container — e.g. carlasim/carla — run alongside this one, not built or
#  launched from here.
# =============================================================================
ARG BASE_IMAGE=nvidia/cuda:13.0.3-cudnn-devel-ubuntu22.04
FROM ${BASE_IMAGE}

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

RUN apt-get update && apt-get install -y --no-install-recommends \
        python3 python3-dev python3-pip \
        git wget curl ca-certificates build-essential \
    && rm -rf /var/lib/apt/lists/* \
    && ln -sf /usr/bin/python3 /usr/bin/python

WORKDIR /workspace

# --- uv + Python deps ---------------------------------------------------------
#  torch/torchvision resolve from PyTorch's CUDA index; everything else (carla,
#  nuscenes-devkit, ...) resolves from PyPI. The lockfile pins the exact
#  resolved set, including which CUDA index the torch wheels came from.
ARG UV_LOCKFILE=uv.lock
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /usr/local/bin/
COPY pyproject.toml ./
COPY ${UV_LOCKFILE} ./uv.lock
RUN uv sync --frozen --no-dev

ENV PATH="/workspace/.venv/bin:$PATH"

COPY tests/smoke_test.py .

CMD ["/bin/bash"]
