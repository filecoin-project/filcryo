# Filcryo architecture and deployment docs

Filcryo is mostly a Lotus node bundled with some bash scripts into a Docker container.

* The Lotus version we run makes use of optimized [chain-ranged export](https://github.com/filecoin-project/lotus/pull/9192), to be upstreamed.
* Assumes and hardcodes a Google Cloud storage bucket (`fil-mainnet-archival-snapshots`).
* The default entrypoint [`scripts/entrypoint.sh`](scripts/entrypoint.sh) will:
  * Unless `/root/.lotus`, already present, initialize lotus from the latest archival snapshot in gcloud storage.
  * Wait until Lotus head catches up.
  * Wait until the time it can export the next snapshot (2880 epochs + 900 finality-epochs + 15).
  * Export, compress, upload to bucket
  * Repeat.
* While the wait-export loop is ongoing, the export some promethus metrics into files (`/root/metrics/metrics.prom`): current lotus height, latest snapshot epoch etc.

The bash scripts and functions used are part of [`filcryo.sh`](scripts/filcryo.sh). A container can potentially be started with a custom entrypoint and the functions re-used for manual archival tasks (running parallel snapshots etc).

Filcryo expects to run in "host" mode in a machine in GCP which has the right access scopes to the `fil-mainnet-archival-snapshots` storage. There is no configuration to this regard, and it expects to work out of the box (`gcloud` and `gsutil` are used).

## Operation in production

Running in production consists of:

* Running the filcryo docker container
* Collecting metrics and logs

In order to collect metrics and logs we use Grafana Agent. For simplicity, running both containers is done using [`docker-compose.yml`](docker-compose.yml). The main thing done is that it sets the volume mounts correctly so that the Grafana agent read the `metrics.prom` file generated in the Filcryo container.

Grafana Agent is configured with [`config.yaml`](grafana-agent/config.yaml). The configuration makes it:
  * Launch node_exporter (grabs all host machine metrics)
  * Collect all docker containers logs
  * Upload everything to Grafana Cloud (urls hardcoded)

**Note that Grafana Agent picks up the configuration directly from Github main-branch (see `-config.file` flag in `docker-compose.yml`)**. This avoids having to pack up or provide the configuration on the side (and then mount it when running the container).

A `Filcryo` Grafana dashboard exists and tracks all the relevant stuff.

![image](https://user-images.githubusercontent.com/1027022/214831509-eca73672-79ad-42f3-b30c-71ebad00148a.png)


## Deployment

Deployments are performed via Github Actions. TODO.
