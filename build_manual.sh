#!/usr/bin/env bash
set -euo pipefail

IMAGE="gueraf/self_hosted_cuda_runner"

ARCH=$(uname -m)
case $ARCH in
    x86_64)
        PLATFORM="linux/amd64"
        TAG="latest"
        ;;
    aarch64|arm64)
        PLATFORM="linux/arm64"
        TAG="arm"
        ;;
    *)
        echo "Unsupported architecture: $ARCH"
        exit 1
        ;;
esac

echo "Building and pushing for $ARCH ($PLATFORM) with tag $TAG"
docker buildx build --platform "$PLATFORM" -t "$IMAGE:$TAG" --push .

echo "Done."
