# :cook: Filet

Filet is a simple Docker image to get data from Filecoin snapshots using [Lily](https://github.com/filecoin-project/lily).

## :rocket: Usage

The `davidgasquez/filet` image available on Docker Hub is configured to run the `walk.sh` script, which will download the latest snapshot, import it into a local Lily node, and run all tasks. CSVs will be saved under `/tmp/data`.

To save the CSVs and Lily datastore locally, you can run `make run` or the following command:

```bash
docker run  -it -v $PWD/.lily:/var/lib/lily -v $PWD:/tmp/data davidgasquez/filet:lastest
```
