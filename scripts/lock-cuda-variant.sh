#!/usr/bin/env bash
# Generate a secondary uv lockfile resolved against a different PyTorch CUDA
# wheel index than the one pyproject.toml declares.
#
#   ./scripts/lock-cuda-variant.sh cu126   ->  writes uv-cu126.lock
#
# The Docker image ships one CUDA variant per lockfile (see docker/Dockerfile's
# UV_LOCKFILE build arg). pyproject.toml stays the single source of truth for
# dependency *versions*; only the index the torch wheels come from differs.
#
# Resolution happens in a temp copy of the project, so pyproject.toml and the
# primary uv.lock in the working tree are never modified.
set -euo pipefail

if [[ $# -ne 1 ]]; then
    echo "usage: $(basename "$0") <cuda-tag>   e.g. $(basename "$0") cu126" >&2
    exit 2
fi

target_tag=$1
if [[ ! $target_tag =~ ^cu[0-9]+$ ]]; then
    echo "error: cuda tag must look like 'cu126' or 'cu130', got '$target_tag'" >&2
    exit 2
fi

repo_root=$(git -C "$(dirname "$0")" rev-parse --show-toplevel)
pyproject="$repo_root/pyproject.toml"

current_tag=$(sed -n 's#^url = "https://download.pytorch.org/whl/\(cu[0-9]*\)".*#\1#p' "$pyproject")
if [[ -z $current_tag ]]; then
    echo "error: no PyTorch CUDA index URL found in $pyproject" >&2
    exit 1
fi
if [[ $current_tag == "$target_tag" ]]; then
    echo "error: $target_tag is already the index in pyproject.toml; its lock is uv.lock" >&2
    exit 1
fi

if ! curl --silent --fail --head "https://download.pytorch.org/whl/$target_tag/" >/dev/null; then
    echo "error: PyTorch publishes no '$target_tag' index" >&2
    exit 1
fi

workdir=$(mktemp -d)
trap 'rm -rf "$workdir"' EXIT

cp "$pyproject" "$workdir/pyproject.toml"
# Seeding the resolver with the primary lock keeps every non-torch package
# pinned to the same version across variants.
cp "$repo_root/uv.lock" "$workdir/uv.lock"
sed -i.bak "s/$current_tag/$target_tag/g" "$workdir/pyproject.toml"

echo "resolving against the $target_tag index (from $current_tag)..."
# torch/torchvision must be forced to re-resolve — the seeded lock's entries
# would otherwise be treated as already satisfying the (now different) index.
uv lock --project "$workdir" --upgrade-package torch --upgrade-package torchvision

output="$repo_root/uv-$target_tag.lock"
cp "$workdir/uv.lock" "$output"
echo "wrote ${output#"$repo_root"/}"
