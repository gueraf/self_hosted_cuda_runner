ARG BASE_IMAGE=nvidia/cuda:12.9.1-devel-ubuntu24.04

FROM ${BASE_IMAGE}

ARG RUNNER_VERSION=2.329.0
ARG RUNNER_SHA256_AMD64=194f1e1e4bd02f80b7e9633fc546084d8d4e19f3928a324d512ea53430102e1d
ARG RUNNER_SHA256_ARM64=56768348b3d643a6a29d4ad71e9bdae0dc0ef1eb01afe0f7a8ee097b039bfaaf
ARG TARGETARCH=linux/arm64

# Expect REPO_HTTPS_URL and REPO_TOKEN to be provided at runtime via docker run -e
# COPY --from=ghcr.io/astral-sh/uv:latest /uv /bin/uv

# Create a non-root user for running the GitHub Actions runner
RUN groupadd -r runner && useradd -m -r -g runner runner

RUN apt-get update && apt-get install -y --no-install-recommends \
      curl \
      ca-certificates \
      libicu-dev \
      jq \
      git \
      cmake \
      zstd \
      zlib1g-dev \
      libgl1 \
      libglib2.0-0 \
      ffmpeg \
      && apt-get clean && rm -rf /var/lib/apt/lists/* && \
    mkdir actions-runner && \
    cd actions-runner && \
    case ${TARGETARCH} in \
      amd64) ARCH=x64; SHA256=${RUNNER_SHA256_AMD64} ;; \
      arm64) ARCH=arm64; SHA256=${RUNNER_SHA256_ARM64} ;; \
      *) echo "Unsupported architecture: ${TARGETARCH}"; exit 1 ;; \
    esac && \
    curl -o actions-runner-linux-${ARCH}-${RUNNER_VERSION}.tar.gz -L https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-${ARCH}-${RUNNER_VERSION}.tar.gz && \
    echo "${SHA256}  actions-runner-linux-${ARCH}-${RUNNER_VERSION}.tar.gz" | shasum -a 256 -c && \
    tar xzf ./actions-runner-linux-${ARCH}-${RUNNER_VERSION}.tar.gz && \
    chown -R runner:runner /actions-runner && \
    apt-get purge -y --auto-remove && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

WORKDIR /actions-runner

RUN ./bin/installdependencies.sh && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
# Switch to non-root user
USER runner

ENTRYPOINT ["bash","-c","if [ -z \"$REPO_HTTPS_URL\" ] || [ -z \"$REPO_TOKEN\" ]; then echo 'REPO_HTTPS_URL and REPO_TOKEN env vars are required' >&2; exit 1; fi; if [ -n \"$RUNNER_NAME\" ]; then NAME_ARG=\"--name $RUNNER_NAME\"; fi; ./config.sh --url $REPO_HTTPS_URL --token $REPO_TOKEN $NAME_ARG && ./run.sh"]

# Usage (persistent background runner; requires env vars & auto restart):
# docker run -d --restart=always --name gh-runner \
#   -e REPO_HTTPS_URL=https://github.com/owner/repo \
#   -e REPO_TOKEN=YOUR_REGISTRATION_TOKEN \
#   -e RUNNER_NAME=custom-runner-name \
#   gueraf/self_hosted_cuda_runner:latest
# (Add '--gpus all' right after 'docker run' if GPU access is needed.)
