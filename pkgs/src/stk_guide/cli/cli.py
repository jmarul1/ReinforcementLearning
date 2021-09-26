import click
from stk_guide.__version__ import __version__


@click.group()
@click.option("-v", "--verbose", is_flag=True, help="Enables verbose mode")
@click.version_option(version=__version__)
@click.pass_context
def cli(ctx, verbose):
    """Get BUY/SELL recommendation"""
    print(__version__)
