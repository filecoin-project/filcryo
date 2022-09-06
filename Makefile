.DEFAULT_GOAL := run

run:
	docker run -it \
        -v $(PWD)/lily:/lily \
        --mount source=lily-data,target=/tmp/lily \
        filecoin/lily:v0.12.0-rc2 \
        init --config /lily/config.toml --repo /tmp/lily --import-snapshot https://snapshots.mainnet.filops.net/minimal/latest

docker-volume:
	docker volume create lily-data
