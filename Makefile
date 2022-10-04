.DEFAULT_GOAL := run

VERSION=v0.3.0
IMAGE=europe-west1-docker.pkg.dev/protocol-labs-data/pl-data/filet

build:
	docker build -t $(IMAGE):$(VERSION) -t $(IMAGE):latest .

run: build
	docker run -it -v ${PWD}/.lily:/var/lib/lily -v ${PWD}:/tmp/data $(IMAGE):$(VERSION)

shell: build
	docker run -it --entrypoint /bin/bash -v ${PWD}/.lily:/var/lib/lily -v${PWD}:/tmp/data $(IMAGE):$(VERSION)

push: build
	docker push $(IMAGE):$(VERSION)
	docker push $(IMAGE):latest

clean:
	sudo rm -rf .lily
	rm -rf *.car *.aria2

send:
	gcloud beta batch jobs submit lily-job-gcs-full-$$RANDOM --config gce_batch_job.json --location europe-north1
