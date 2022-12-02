# :cook: Filet

Filet (**Fil**ecoin **E**xtract **T**ransform) makes it simple to get CSV data from Filecoin Archival Snapshots using [Lily](https://github.com/filecoin-project/lily) and [`sentinel-archiver`](https://github.com/filecoin-project/sentinel-archiver/).

## :rocket: Usage

The `filet` image available on Google Container Artifact Hub. Alternatively, you can build it locally with `make build`.

The following command will generate CSVs from an Filecoin Archival Snapshot:

```bash
docker run -it \
    -v $PWD:/tmp/data \
    europe-west1-docker.pkg.dev/protocol-labs-data/pl-data/filet:latest -- \
    /lily/export.sh archival_snapshot.car.zst .
```

## :hammer: Deployment

The `filet` image can deployed into different environments. We're using Google Cloud Batch. To schedule jobs there, you can run the following command:

```bash
./scripts/send_export_jobs.sh SNAPSHOT_LIST_FILE
```

For more details on the scheduled jobs configuration, you can check the [`gce_batch_job.json`](./gce_batch_job.json) file.

## :alarm_clock: Scheduling Jobs

You can use the [`send_export_jobs.sh`](scripts/send_export_jobs.sh) script to schedule jobs on Google Cloud Batch. The script takes a file with a list of snapshots as input.

```bash
./scripts/send_export_jobs.sh SNAPSHOT_LIST_FILE [--dry-run]
```

The `SNAPSHOT_LIST_FILE` file should contain a list of snapshots, one per line. The snapshots should be available in the `fil-mainnet-archival-snapshots` Google Cloud Storage bucket.

```
gsutil ls gs://fil-mainnet-archival-snapshots/historical-exports/ | sort --version-sort > all_snapshots.txt
```
