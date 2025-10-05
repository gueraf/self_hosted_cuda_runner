ARG BASE_IMAGE=nvidia/cuda:12.9.1-devel-ubuntu24.04

FROM ${BASE_IMAGE}

ARG repo_https_url
ARG repo_token
ENV REPO_HTTPS_URL=${repo_https_url} \
    REPO_TOKEN=${repo_token}

COPY --from=ghcr.io/astral-sh/uv:latest /uv /bin/uv

RUN mkdir actions-runner && \
    cd actions-runner && \
    curl -o actions-runner-linux-x64-2.328.0.tar.gz -L https://github.com/actions/runner/releases/download/v2.328.0/actions-runner-linux-x64-2.328.0.tar.gz && \
    echo "01066fad3a2893e63e6ca880ae3a1fad5bf9329d60e77ee15f2b97c148c3cd4e  actions-runner-linux-x64-2.328.0.tar.gz" | shasum -a 256 -c && \
    tar xzf ./actions-runner-linux-x64-2.328.0.tar.gz

WORKDIR /actions-runner

ENTRYPOINT ["bash","-c","./config.sh --url $REPO_HTTPS_URL --token $REPO_TOKEN && ./run.sh"]


