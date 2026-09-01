# sim-to-real

[![Build and push Docker image](https://github.com/dwhan89/simtoreal/actions/workflows/docker-build-push.yml/badge.svg)](https://github.com/dwhan89/simtoreal/actions/workflows/docker-build-push.yml)

Calibrated multimodal sensor fusion for sim-to-real autonomous driving. Fuse
camera + IMU (+ optional depth/LiDAR) into an ego/scene state estimate with
calibrated uncertainty. Build and calibrate the fusion module in **CARLA**,
where ground truth is exact, then validate it the way you'd validate a
systemic bias: inject a known sensor bias or extrinsic
miscalibration, confirm the fusion recovers it with correct coverage and no
leftover error, before trusting it. Transfer to real driving logs
(nuScenes/KITTI) and check calibration holds under real distribution shift.
Finally, feed the calibrated estimate to a diffusion policy for a
driving-relevant decision, and show honest fusion improves the downstream
policy versus naive fusion.

Stack: CARLA (simulator + Python client) for the sim side, PyTorch (a
BEVFusion-style fusion backbone, a diffusion policy) for the models,
nuscenes-devkit for the real-data half.

- Environment setup (Docker + uv, smoke test): [`docker/README.md`](docker/README.md)

See [CHANGELOG.md](CHANGELOG.md) for project history.

Licensed under [MIT](LICENSE).
