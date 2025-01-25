from typing import Any, Self
from datetime import datetime, timedelta
from attrs import define, field
from pandas import concat
from yfinance import Ticker
from robin_stocks.robinhood import get_ratings
from .prices import Prices
from .options import Options, OptionsEnum


class StockEnum:
    SUMMARY = "summary"
    NEWS = "ratings"


@define
class Stock:
    symbol: str
    company: str = field(default=None)
    prices: Prices = field(default=None, init=False)
    options: Options = field(default=None, init=False)
    info: dict[str, Any] = field(default=None, init=False)
    news: dict = field(init=False)
    _ratings: dict[str, int] = field(init=False)

    def __attrs_post_init__(self) -> None:
        if self.company is None:
            self.company = self.symbol

    def __eq__(self, value: Self):
        if not isinstance(value, self.__class__):
            raise ValueError("Cannot compare to non Stock objects")
        return self.symbol == value.symbol

    @property
    def ratings(self) -> dict[str, int]:
        dt = get_ratings(self.symbol)
        self.news = dt[StockEnum.NEWS]
        return dt[StockEnum.SUMMARY]

    def populate_prices(self, years_back: int = 5) -> None:
        start = datetime.now() - timedelta(days=int(years_back * 365))
        tic = Ticker(self.symbol)
        df = tic.history(start=start)
        self.prices = Prices(df.to_dict("index"))
        self.info = tic.info

    def populate_options(self, max_number: int = None) -> None:
        if max_number is None:
            max_number = -1
        tic = Ticker(self.symbol)
        self.info = tic.info
        calls, puts = [], []
        for option in tic.options[:max_number]:
            tic_options = tic.option_chain(option)
            _calls, _puts = tic_options.calls, tic_options.puts
            _calls[OptionsEnum.EXPIRATION.value] = datetime.strptime(option, "%Y-%m-%d").date()
            _puts[OptionsEnum.EXPIRATION.value] = datetime.strptime(option, "%Y-%m-%d").date()
            calls.append(tic_options.calls)
            puts.append(tic_options.puts)
        self.options = Options(concat(calls), concat(puts))

    def __hash__(self) -> int:
        return hash(self.symbol)

    def __str__(self) -> str:
        return self.symbol
