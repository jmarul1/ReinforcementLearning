import click
from stk_guide import __version__


@click.group()
@click.option("-v", "--verbose", is_flag=True, help="Enables verbose mode")
@click.version_option(version=0.0)
@click.pass_context
def cli(ctx, verbose):
    """Get BUY/SELL recommendation"""
    print(1)

