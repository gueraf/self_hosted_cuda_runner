#!/usr/bin/env bash
set -euo pipefail

# Determine architecture for runner tags and docker image tag
ARCH=$(uname -m)
if [[ "${ARCH}" == "x86_64" ]]; then
  ARCH_LABEL="self-hosted-x86"
  DOCKER_TAG="latest"
elif [[ "${ARCH}" == "aarch64" || "${ARCH}" == "arm64" ]]; then
  ARCH_LABEL="self-hosted-arm"
  DOCKER_TAG="arm"
else
  echo "Unsupported architecture: ${ARCH}" >&2
  exit 1
fi

# Pull the latest image before starting the runner
echo "Pulling latest runner image for ${ARCH}..."
docker pull gueraf/self_hosted_cuda_runner:${DOCKER_TAG}

# Ensure jq is available (install if missing)
if ! command -v jq >/dev/null 2>&1; then
  echo "jq not found, attempting installation via apt..."
  if command -v apt >/dev/null 2>&1; then
    sudo apt update -y && sudo apt install -y jq
  else
    echo "apt not available; please install jq manually." >&2
    exit 1
  fi
fi

# Derive a short-lived registration token using the provided PAT (export GITHUB_ACCESS_TOKEN or PAT before calling)
PAT="${GITHUB_ACCESS_TOKEN:-${PAT:-}}"
if [[ -z "${PAT}" ]]; then
  echo "Missing PAT. Please set GITHUB_ACCESS_TOKEN or PAT in the environment." >&2
  exit 1
fi

echo "Requesting GitHub runner registration token..."
REG_TOKEN="$(curl -fsS -X POST \
  -H 'Accept: application/vnd.github+json' \
  -H "Authorization: token ${PAT}" \
  https://api.github.com/repos/gueraf/flash-attention/actions/runners/registration-token | jq -r '.token')"

if [[ -z "${REG_TOKEN}" || "${REG_TOKEN}" == "null" ]]; then
  echo "Failed to obtain a runner registration token from GitHub." >&2
  exit 1
fi

echo "Obtained registration token: ${REG_TOKEN}"

# Remove existing container if it exists (force)
if docker ps -a --format '{{.Names}}' | grep -qx gh-runner-fa2; then
  echo "Removing existing gh-runner container..."
  docker rm -f gh-runner-fa2 >/dev/null
fi

echo "Starting runner container..."
DOCKER_HOST_HOSTNAME="$(hostname)"
echo "Docker host hostname: ${DOCKER_HOST_HOSTNAME}"
echo "Runner will be registered as: ${DOCKER_HOST_HOSTNAME}"
docker run -d --restart=always --name gh-runner-fa2 \
    --gpus all \
    --shm-size 8G \
    -e REPO_HTTPS_URL=https://github.com/gueraf/flash-attention \
    -e REPO_TOKEN="${REG_TOKEN}" \
    -e RUNNER_NAME="${DOCKER_HOST_HOSTNAME}" \
    -e RUNNER_LABELS="self-hosted,${ARCH_LABEL},Linux,gpu,${DOCKER_HOST_HOSTNAME}" \
    -e DOCKER_HOST_HOSTNAME="${DOCKER_HOST_HOSTNAME}" \
    gueraf/self_hosted_cuda_runner:${DOCKER_TAG}
