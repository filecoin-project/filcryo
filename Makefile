.DEFAULT_GOAL := run

VERSION=v0.1.1
IMAGE=davidgasquez/filet

build:
	docker build -t $(IMAGE):$(VERSION) -t $(IMAGE):latest .

run: build
	docker run -it -v ${PWD}/.lily:/lily/.lily $(IMAGE)

shell: build
	docker run -it --entrypoint /bin/bash -v ${PWD}/.lily:/lily/.lily $(IMAGE)

push: build
	docker push $(IMAGE):$(VERSION)
	docker push $(IMAGE):latest

clean:
	sudo rm -rf .lily
