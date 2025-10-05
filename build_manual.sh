#!/usr/bin/env bash
set -euo pipefail

IMAGE="gueraf/self_hosted_cuda_runner"
TAG="${1:-latest}"

REPO_HTTPS_URL="${REPO_HTTPS_URL:-}"
REPO_TOKEN="${REPO_TOKEN:-}"

echo "Building image $IMAGE:$TAG (repo url: '${REPO_HTTPS_URL}')"
docker build \
  --build-arg repo_https_url="$REPO_HTTPS_URL" \
  --build-arg repo_token="$REPO_TOKEN" \
  -t "$IMAGE:$TAG" .

echo "Pushing image $IMAGE:$TAG"
docker push "$IMAGE:$TAG"

echo "Done."
