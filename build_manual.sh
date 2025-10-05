#!/usr/bin/env bash
set -euo pipefail

IMAGE="gueraf/self_hosted_cuda_runner"
TAG="${1:-latest}"

echo "Building image $IMAGE:$TAG"
docker build -t "$IMAGE:$TAG" .

echo "Pushing image $IMAGE:$TAG"
docker push "$IMAGE:$TAG"

echo "Done."
