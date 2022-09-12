.DEFAULT_GOAL := run

IMAGE=davidgasquez/filet:v0.1.1

build:
	docker build -t $(IMAGE) .

run: build
	docker run -it $(IMAGE)

push: build
	docker push $(IMAGE)

# Running things in separate containers

init: data-volume
	docker run -it \
        -v $(PWD)/lily:/lily \
        --mount source=lily-data,target=/tmp/lily \
        filecoin/lily:v0.12.0 \
        init --config /lily/config.toml --repo /tmp/lily --import-snapshot https://snapshots.mainnet.filops.net/minimal/latest

data-volume:
	docker volume create lily-data

daemon:
	docker run -it \
        -v $(PWD):/lily \
        -v $(PWD)/data:/tmp/data \
        --mount source=lily-data,target=/tmp/lily \
        --network host \
        -e GOLOG_LOG_FMT=json \
        -e GOLOG_FILE=/lily/log.json \
        -e GOLOG_OUTPUT=file+stdout \
        filecoin/lily:v0.12.0 \
        daemon --config /lily/config.toml --repo /tmp/lily

export:
	docker run -it \
        --network host \
        -v $(PWD)/data:/tmp/data \
        filecoin/lily:v0.12.0 \
        job run --storage=CSV walk --from 2136401 --to 2138400

clean:
	docker volume rm lily-data

shell:
	docker run -it --entrypoint /bin/bash --network host --mount source=lily-data,target=/tmp/lily filecoin/lily:v0.12.0
