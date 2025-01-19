from typing import Self
from datetime import datetime, timedelta
from attrs import define, field
from yfinance import Ticker
from .prices import Prices


@define
class Stock:
    symbol: str
    company: str = field(default=None)
    prices: Prices = field(default=None, init=False)

    def __attrs_post_init__(self) -> None:
        if self.company is None:
            self.company = self.symbol

    def __eq__(self, value: Self):
        if not isinstance(value, self.__class__):
            raise ValueError("Cannot compare to non Stock objects")
        return self.symbol == value.symbol

    def populate_prices(self, years_back: int = 5) -> None:
        start = datetime.now() - timedelta(days=int(years_back * 365))
        df = Ticker(self.symbol).history(start=start)
        self.prices = Prices(df.to_dict("index"))

    def __hash__(self) -> int:
        return hash(self.symbol)
