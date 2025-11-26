#!/usr/bin/env bash
set -euo pipefail

IMAGE="gueraf/self_hosted_cuda_runner"


# echo "Building and pushing multi-arch image $IMAGE:$TAG for platforms linux/amd64,linux/arm64"
# docker buildx build --platform linux/amd64,linux/arm64 -t "$IMAGE:$TAG" --push .
docker buildx build --platform linux/amd64 -t "$IMAGE:latest" -t "$IMAGE:self-hosted" --build-arg BASE_IMAGE=nvidia/cuda:12.9.1-devel-ubuntu22.04 --push .
# docker buildx build --platform linux/arm64 -t "$IMAGE:arm" --push .

echo "Done."
