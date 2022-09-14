from setuptools import setup, find_packages

setup(
    name="filet",
    version="0.1.3",
    packages=find_packages(),
    install_requires=["typer[all]", "requests"],
    entry_points={
        "console_scripts": ["filet = filet.main:app"],
    },
)
