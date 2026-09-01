# =============================================================================
#  Sim-to-real project image — CARLA client + PyTorch stack (BEVFusion-style
#  fusion backbone, diffusion policy). Base: CUDA 12.6 + cuDNN, matching the
#  torch==2.13.0+cu126 wheel pulled from PyTorch's own index.
#
#  This image holds the CARLA *client* and the training code only. The CARLA
#  *simulator* (the Unreal-Engine server this client talks to over RPC) is its
#  own container — e.g. carlasim/carla — run alongside this one, not built or
#  launched from here.
# =============================================================================
FROM nvidia/cuda:12.6.3-cudnn-devel-ubuntu22.04

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
#  torch/torchvision resolve from PyTorch's cu126 index (see pyproject.toml);
#  everything else (carla, nuscenes-devkit, ...) resolves from PyPI. uv.lock
#  pins the exact resolved set.
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /usr/local/bin/
COPY pyproject.toml uv.lock ./
RUN uv sync --frozen --no-dev

ENV PATH="/workspace/.venv/bin:$PATH"

COPY tests/smoke_test.py .

CMD ["/bin/bash"]
