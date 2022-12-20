# :ice_cube: Filcryo

Filcryo makes it simple to freeze chunks of the Filecoin chain with all nutritional properties (archival grade quality). They can then be cooked with [Filet](https://github.com/filecoin-project/filcryo).

## :rocket: Usage

The `filcryo` image available on Google Container Artifact Hub. Alternatively, you can build it locally with `make build`.

The following command will make a new snapshot based on an existing snapshot:

```bash
docker run -it \
    -v $PWD:/tmp/data \
    europe-west1-docker.pkg.dev/protocol-labs-data/pl-data/filcryo:latest -- \
    <start_epoch>
```

`<start_epoch>` must correspond to the start epoch of an existing snapshot in `gcloud storage ls gs://fil-mainnet-archival-snapshots/historical-exports/`. The new snapshot will be compressed and uploaded to this destination as well.

## :alarm_clock: Scheduling Jobs

You can use the [`send_export_jobs.sh`](scripts/send_export_jobs.sh) script to schedule a job on Google Cloud Batch that runs the export.

```bash
./scripts/send_export_jobs.sh <start_epoch> [--dry-run]
```

For more details on the scheduled jobs configuration, you can check the [`gce_batch_job.json`](./gce_batch_job.json) file.
