#!/usr/bin/env bash
set -euo pipefail

IMAGE="gueraf/self_hosted_cuda_runner"
TAG="${1:-latest}"

# echo "Building and pushing multi-arch image $IMAGE:$TAG for platforms linux/amd64,linux/arm64"
# docker buildx build --platform linux/amd64,linux/arm64 -t "$IMAGE:$TAG" --push .
docker buildx build -t "$IMAGE:$TAG" --push .

echo "Done."
