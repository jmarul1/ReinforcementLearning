from datetime import datetime
from numbers import Number
from typing import Literal
from pandas import DataFrame
import pytest
from stk_guide.entities.options import Options
from stk_guide.entities.prices import Prices
from stk_guide.entities.rating import Rating
from stk_guide.entities.stock import Stock
from stk_guide.entities.stocks import Stocks


def test_stock() -> None:
    stock = Stock("AAPL", "Apple")
    assert stock.symbol == "AAPL"
    assert stock.prices is None
    assert stock.options is None
    assert isinstance(stock.info, dict)


def test_stocks(stock_sample: Stock) -> None:
    stocks = Stocks([stock_sample])
    stocks.append(stock_sample)
    assert isinstance(stocks, Stocks)
    assert len(stocks) == 1
    with pytest.raises(ValueError):
        stocks.append("INTC")


def test_stock_price_dl(stock_sample: Stock) -> None:
    stock_sample.populate_prices(days_back=0.1)
    assert isinstance(stock_sample.prices, Prices)


def test_stock_options_dl(stock_sample: Stock) -> None:
    stock_sample.populate_options()
    assert isinstance(stock_sample.options, Options)


def test_prices() -> None:
    price = {"Close": 111}
    date = datetime.now()
    prices = Prices({date: price})
    test = list(prices)[0]
    assert isinstance(prices, dict)
    assert isinstance(test, datetime)
    assert isinstance(prices[test], dict) and isinstance(prices[test]["Close"], Number)
    with pytest.raises(ValueError, match="Keys must be datetime objects"):
        Prices({100: {"Close": 111}})
    with pytest.raises(ValueError, match="Price must be a dict"):
        Prices({date: 111})
    with pytest.raises(ValueError, match="Price Key must be a str"):
        Prices({date: {111: 111}})
    with pytest.raises(ValueError, match="Price value must be a number"):
        Prices({date: {"Close": "111"}})


def test_options() -> None:
    calls = DataFrame({"bid": [0.5, 0.1]})
    puts = DataFrame({"bid": [0.5, 0.1]})
    test = Options(calls, puts)
    assert isinstance(test.calls, DataFrame) and not test.calls.empty
    assert isinstance(test.puts, DataFrame) and not test.puts.empty


def test_options_summary(options_sample: Options) -> None:
    result = options_sample.sumarize_calls()
    assert isinstance(result, DataFrame)
    assert not result.empty


@pytest.mark.parametrize("ratings", ["robinhood_ratings", "finhub_ratings"])
def test_stock_ratings(stock_sample: Stock, ratings: Literal["robinhood_ratings"] | Literal["finhub_ratings"]) -> None:
    test = getattr(stock_sample, ratings)
    assert isinstance(test, list)
    assert isinstance(test[0], Rating)
