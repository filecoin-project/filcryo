FROM filecoin/lily:v0.12.0

# Install aria2
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install --no-install-recommends aria2

# Add required files
COPY config.toml scripts /lily/

ENTRYPOINT [ "/bin/bash" ]

CMD [ "/lily/walk.sh" ]
