FROM filecoin/lily:v0.12.0

# Install aria2
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install --no-install-recommends aria2

# Install gcloud
RUN echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] http://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list && curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg  add - && apt-get update -y && apt-get install google-cloud-cli -y

# Add required files
COPY config.toml scripts /lily/

# Create data folder
RUN mkdir /tmp/data

# Run script
ENTRYPOINT [ "/bin/bash" ]
CMD [ "/lily/walk.sh" ]
