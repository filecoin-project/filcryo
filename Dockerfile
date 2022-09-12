FROM filecoin/lily:v0.12.0

COPY config.toml walk.sh /lily/

ENTRYPOINT ["/lily/walk.sh"]
