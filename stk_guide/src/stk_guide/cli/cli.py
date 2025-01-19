import importlib.metadata
from logging import DEBUG, INFO
import click
from ..entities.stocks import Stocks
from ..strategies.historic_price import Sequence
from ..logger import Logger


# @click.group()
@click.command()
@click.option("--strategies")
@click.option("--stocks")
@click.option("-v", "--verbose", is_flag=True, help="Enables verbose mode")
@click.version_option(version="1.0")
# @click.pass_context
def cli(stocks: str, strategies: str, verbose: bool):  # pylint: disable = unused-argument
    """Get BUY/SELL recommendation"""

    # ctx.ensure_object(dict)
    # ctx.obj["VERBOSE"] = DEBUG if verbose else INFO
    Logger(verbose_level=verbose)
    strategies_fab = {"sequence": Sequence}
    for name in strategies.split(","):
        strategy = strategies_fab[name]()
        _stocks = Stocks(stocks.split(","))
        df = strategy(_stocks)
        print(df)
