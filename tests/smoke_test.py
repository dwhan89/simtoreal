"""
Smoke test — run this the moment an instance boots, before doing real work.
Stack: PyTorch (fusion backbone + diffusion policy) + the CARLA Python client
(talks to a separately-running CARLA simulator) + nuscenes-devkit for the
real-data half. On the cloud GPU target it catches the two things that
actually go wrong: (1) torch can't see the GPU, (2) the CARLA client wheel is
missing. CARLA has no macOS wheel, so on local macOS dev only the torch and
nuscenes-devkit checks run — that's expected, not an error.

Usage:  python smoke_test.py
Expect: every section prints a device/status and ends with "All checks passed."
"""

import sys

expect_gpu = sys.platform != "darwin"
print(f"platform = {sys.platform} | GPU expected: {expect_gpu}\n")

checks_ok = []

# --- 1. PyTorch (everything trains on this) -----------------------------------
print("== PyTorch ==")
import torch

gpu_ok = torch.cuda.is_available()
print(f"torch {torch.__version__} | cuda available: {gpu_ok}")
if gpu_ok:
    x = torch.ones(1000, 1000, device="cuda")
    y = (x @ x).cpu()
    print(f"matmul on GPU OK, result shape: {tuple(y.shape)}")
elif not expect_gpu:
    print("-- CPU/MPS build, as expected for local macOS dev.")
else:
    print("!! torch has no CUDA device — check the driver and the cu126 wheel install.")
checks_ok.append(gpu_ok or not expect_gpu)
print()

# --- 2. CARLA client (talks to the separately-running CARLA simulator) -------
print("== CARLA client ==")
if sys.platform == "linux":
    carla_ok = False
    try:
        import carla  # noqa: F401

        print("carla client imported OK (no server connection attempted).")
        carla_ok = True
    except Exception as e:
        print(f"!! carla import failed ({e}).")
    checks_ok.append(carla_ok)
else:
    print("-- skipped: no CARLA wheel for this platform; only runs on the Linux target.")
print()

# --- 3. nuscenes-devkit (real driving-log half of the project) ---------------
print("== nuscenes-devkit ==")
import nuscenes  # noqa: F401

print("nuscenes-devkit imported OK.")
print()

print("All checks passed." if all(checks_ok) else "Finished with warnings — see !! lines above.")
