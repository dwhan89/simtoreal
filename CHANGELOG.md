# Changelog

Notable changes to this project. Newest first.

## [Unreleased]

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
