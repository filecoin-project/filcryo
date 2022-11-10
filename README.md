# :cook: Filet

Filet is just a Docker container that makes it simple to get CSV data from Filecoin Archival Snapshots using [Lily](https://github.com/filecoin-project/lily) and [`sentinel-archiver`](https://github.com/filecoin-project/sentinel-archiver/).

## :rocket: Usage

The `filet` image available on Google Container Artifact Hub. You can run the `export.sh` script pointing it to a Filecoin Archival Snapshot. CSVs will produced and saved to the provided directory.

```bash
./export.sh [SNAPSHOT_FILE] [EXPORT_DIR]
```

You can run the following command to generate CSVs from an Filecoin Archival Snapshot:

```bash
docker run -it \
    -v $PWD:/tmp/data \
    europe-west1-docker.pkg.dev/protocol-labs-data/pl-data/filet:latest -- \
    /lily/export.sh archival_snapshot.car.zst .
```
