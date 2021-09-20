from codecs import open
from setuptools import setup, find_packages
from pathlib import Path

current_dir = Path(__file__).parent
about = {}
with open(current_dir / "src/stk_guide/__version__.py") as fin:
    exec(fin.read(), about)

with open("README.md") as fin:
    readme = fin.read()

packages = find_packages(where="src")
requires = [
    "click",
    "terminaltables",
    "daiquiri",
    "numpy",
    "progress",
    "pytest",
]

setup(
    name=about["__title__"],
    version=about["__version__"],
    description=about["__description__"],
    long_description=readme,
    author=about["__author__"],
    author_email=about["__author_email__"],
    url=about["__url__"],
    packages=packages,
    package_dir={"": "src"},
    include_package_data=True,
    python_requires=">=3.7.4",
    install_requires=requires,
    #    license=about["__license__"],
    zip_safe=False,
    entry_points={"console_scripts": ["stkg=stk_guide.cli.cli:cli"]},
)
