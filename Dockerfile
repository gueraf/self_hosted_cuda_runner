ARG BASE_IMAGE=nvidia/cuda:12.9.1-devel-ubuntu24.04

FROM ${BASE_IMAGE}


# Expect REPO_HTTPS_URL and REPO_TOKEN to be provided at runtime via docker run -e
COPY --from=ghcr.io/astral-sh/uv:latest /uv /bin/uv

RUN mkdir actions-runner && \
    cd actions-runner && \
    curl -o actions-runner-linux-x64-2.328.0.tar.gz -L https://github.com/actions/runner/releases/download/v2.328.0/actions-runner-linux-x64-2.328.0.tar.gz && \
    echo "01066fad3a2893e63e6ca880ae3a1fad5bf9329d60e77ee15f2b97c148c3cd4e  actions-runner-linux-x64-2.328.0.tar.gz" | shasum -a 256 -c && \
    tar xzf ./actions-runner-linux-x64-2.328.0.tar.gz

WORKDIR /actions-runner

ENTRYPOINT ["bash","-c","if [ -z \"$REPO_HTTPS_URL\" ] || [ -z \"$REPO_TOKEN\" ]; then echo 'REPO_HTTPS_URL and REPO_TOKEN env vars are required' >&2; exit 1; fi; ./config.sh --url $REPO_HTTPS_URL --token $REPO_TOKEN && ./run.sh"]








# Usage (persistent background runner; requires env vars & auto restart):
# docker run -d --restart=always --name gh-runner \
#   -e REPO_HTTPS_URL=https://github.com/owner/repo \
#   -e REPO_TOKEN=YOUR_REGISTRATION_TOKEN \
#   gueraf/self_hosted_cuda_runner:latest
# (Add '--gpus all' right after 'docker run' if GPU access is needed.)
