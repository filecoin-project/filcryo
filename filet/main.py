import subprocess
import typer
import requests

LATEST_SNAPSHOT_URL = requests.get(
    "https://snapshots.mainnet.filops.net/minimal/latest",
    allow_redirects=False,
    timeout=10,
).headers["Location"]

app = typer.Typer()


@app.command()
def download(
    url: str = typer.Argument(LATEST_SNAPSHOT_URL, help="The URL to download"),
    folder: str = typer.Option(
        ".",
        "-f",
        help="The folder to place the snapshot in",
    ),
):
    """Download a file from URL"""
    print(f"Downloading {url} to {folder}")
    subprocess.run(
        ["aria2c", "-x16", "-s16", url, "-d", folder, "--log-level", "notice"],
        check=True,
    )


if __name__ == "__main__":
    app()
