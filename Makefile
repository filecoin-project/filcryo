.DEFAULT_GOAL := run

init:
	docker run -it \
        -v $(PWD)/lily:/lily \
        --mount source=lily-data,target=/tmp/lily \
        filecoin/lily:v0.12.0-rc2 \
        init --config /lily/config.toml --repo /tmp/lily --import-snapshot https://snapshots.mainnet.filops.net/minimal/latest

data-volume:
	docker volume create lily-data

clean:
	docker volume rm lily-data
