ARG BASE_IMAGE=nvidia/cuda:12.9.1-devel-ubuntu24.04

FROM ${BASE_IMAGE}


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
      && apt-get clean && rm -rf /var/lib/apt/lists/* && \
    mkdir actions-runner && \
    cd actions-runner && \
    curl -o actions-runner-linux-x64-2.328.0.tar.gz -L https://github.com/actions/runner/releases/download/v2.328.0/actions-runner-linux-x64-2.328.0.tar.gz && \
    echo "01066fad3a2893e63e6ca880ae3a1fad5bf9329d60e77ee15f2b97c148c3cd4e  actions-runner-linux-x64-2.328.0.tar.gz" | shasum -a 256 -c && \
    tar xzf ./actions-runner-linux-x64-2.328.0.tar.gz && \
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
