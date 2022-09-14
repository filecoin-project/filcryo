FROM golang:1.18 AS builder

RUN apt-get update && apt-get install -y ca-certificates build-essential clang ocl-icd-opencl-dev ocl-icd-libopencl1 jq libhwloc-dev

ARG RUST_VERSION=nightly
ENV XDG_CACHE_HOME="/tmp"

ENV RUSTUP_HOME=/usr/local/rustup \
    CARGO_HOME=/usr/local/cargo \
    PATH=/usr/local/cargo/bin:$PATH

RUN wget "https://static.rust-lang.org/rustup/dist/x86_64-unknown-linux-gnu/rustup-init"; \
    chmod +x rustup-init; \
    ./rustup-init -y --no-modify-path --profile minimal --default-toolchain $RUST_VERSION; \
    rm rustup-init; \
    chmod -R a+w $RUSTUP_HOME $CARGO_HOME; \
    rustup --version; \
    cargo --version; \
    rustc --version;

# Build Lily Shed
RUN git clone https://github.com/kasteph/lily-shed.git /tmp/lily-shed
WORKDIR /tmp/lily-shed
RUN go build

# Build Lily
RUN git clone --branch v0.12.0 https://github.com/filecoin-project/lily /tmp/lily
WORKDIR /tmp/lily
RUN export CGO_ENABLED=1 && make clean all

FROM mcr.microsoft.com/vscode/devcontainers/python:3.10

# Install aria2
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install --no-install-recommends aria2

# Copy binaries from builder
COPY --from=builder /tmp/lily/lily /usr/bin/lily
COPY --from=builder /tmp/lily-shed/lily-shed /usr/bin/lily-shed
COPY --from=builder /usr/lib/x86_64-linux-gnu/libOpenCL.so* /lib/
COPY --from=builder /usr/lib/x86_64-linux-gnu/libhwloc.so* /lib/
COPY --from=builder /usr/lib/x86_64-linux-gnu/libnuma.so* /lib/
COPY --from=builder /usr/lib/x86_64-linux-gnu/libltdl.so* /lib/

RUN pip3 --disable-pip-version-check --no-cache-dir install "typer[all]" requests \
    && rm -rf /tmp/pip-tmp

# Add required files
COPY config.toml walk.sh /lily/

ENTRYPOINT [ "/bin/bash" ]

CMD [ "/lily/walk.sh" ]
