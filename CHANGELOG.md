# Changelog

Notable changes to this project. Newest first.

## [Unreleased]

- Published two CUDA variants of the client image (`:cuda13`, `:cuda126`) so a
  cloud host can be picked by driver support, built as a matrix in CI.
- Pinned the client image to CUDA 13.0 + torch 2.13.0/cu130 (was CUDA 12.6).
- Rewrote the RunPod deployment docs around two separate pods (simulator +
  client) connected over the network — RunPod pods have no Docker daemon, so
  `docker-compose.yml` can't run there directly.

## Stack: CARLA + PyTorch (current)

- Swapped the all-JAX/MJX simulation stack for CARLA + PyTorch as the
  modeling stack.
- Added a `docker-compose.yml` to launch CARLA and the client image together
  for cloud deployment.
- Added a GitHub Actions workflow to build and push the client image to
  Docker Hub.
- Added pre-commit with ruff lint + format.
- Pointed VS Code at the project virtualenv.

## Stack: all-JAX residual physics (earlier)

- Dropped sbi/torch in favor of an all-JAX residual-physics stack.
- Upgraded to the latest MJX/JAX/sbi stack; shimmed brax for JAX 0.11.

## Project setup

- Added an MIT license.
- Switched package management to uv.
- Documented cross-platform image builds.
- Added a local CPU dev path alongside the Linux CUDA target.
- Initial project scaffolding.
