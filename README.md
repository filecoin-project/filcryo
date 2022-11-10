# :cook: Filet

Filet is a simple Docker image to get data from Filecoin snapshots using [Lily](https://github.com/filecoin-project/lily).

## :rocket: Usage

The `filet` image available on Google Container Artifact Hub is configured to run the `walk.sh` script, which will download the latest snapshot, import it into a local Lily node, and run all tasks. CSVs will be saved under `/tmp/data`.

To save the CSVs and Lily datastore locally, you can run `make run`.

### Exporting CSVs from an archival snapshot

You can run the following command to export CSVs from an archival snapshot to a local `data` folder:

```bash
docker run -it -v $PWD:/workspace europe-west1-docker.pkg.dev/protocol-labs-data/pl-data/filet:v0.5.0.backfill -- /lily/export.sh /workspace/snapshot_0_2882_1666948118.car.zst /workspace/data/
```
