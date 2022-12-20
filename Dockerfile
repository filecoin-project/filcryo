FROM golang:1.18-buster AS builder

ENV SRC_PATH    /build
ENV GO111MODULE on
ENV GOPROXY     https://proxy.golang.org

# Install build deps for lily and sentinel-archiver
RUN apt-get update -y && \
    apt-get install git make ca-certificates jq hwloc libhwloc-dev mesa-opencl-icd ocl-icd-opencl-dev -y && \
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y && \
    . "$HOME/.cargo/env"

WORKDIR $SRC_PATH

RUN git clone --single-branch --depth=2 --branch hsanjuan/chain-export-range-rebased https://github.com/hsanjuan/lotus.git && \
cd lotus && \
CGO_ENABLED=1 make lotus

WORKDIR /gcloud
RUN curl -O https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-412.0.0-linux-x86_64.tar.gz && tar -xf google-cloud-cli-412.0.0-linux-x86_64.tar.gz


FROM buildpack-deps:buster-curl

# Install aria2 and zstd
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install --no-install-recommends aria2 zstd jq python3

ENV SRC_PATH /build

COPY --from=builder $SRC_PATH/lotus/lotus /usr/local/bin/lotus
COPY --from=builder /usr/lib/x86_64-linux-gnu/libOpenCL.so* /lib/
COPY --from=builder /usr/lib/x86_64-linux-gnu/libhwloc.so* /lib/
COPY --from=builder /usr/lib/x86_64-linux-gnu/libnuma.so* /lib/
COPY --from=builder /usr/lib/x86_64-linux-gnu/libltdl.so* /lib/
COPY --from=builder /gcloud/google-cloud-sdk/ /gcloud/

RUN ln -s /gcloud/bin/gcloud /usr/local/bin/gcloud
RUN ln -s /gcloud/bin/gsutil /usr/local/bin/gsutil


# Add required files
COPY scripts gce_batch_job.json /data/

# Create data folder
WORKDIR /data

ENTRYPOINT ["/bin/bash"]
