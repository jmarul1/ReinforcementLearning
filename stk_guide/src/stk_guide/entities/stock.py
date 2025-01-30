from typing import Any, Self
from attrs import define, field
from ..download.downloader import FinhubRating, PriceHistory, StockOptions, StockInfo, RobinhoodRatings
from .prices import Prices
from .rating import Rating


@define
class Stock:
    symbol: str
    company: str = field(default=None)
    prices: Prices = field(default=None, init=False)
    options: StockOptions = field(default=None, init=False)
    info: dict[str, Any] = field(default=None, init=False)

    def __attrs_post_init__(self) -> None:
        if self.company is None:
            self.company = self.symbol
        self.info = StockInfo(self.symbol).download()

    def __eq__(self, value: Self):
        if not isinstance(value, self.__class__):
            raise ValueError("Cannot compare to non Stock objects")
        return self.symbol == value.symbol

    @property
    def robinhood_ratings(self) -> list[Rating]:
        return RobinhoodRatings(self.symbol).download()

    @property
    def finhub_ratings(self) -> list[Rating]:
        return FinhubRating(self.symbol).download()

    def populate_prices(self, days_back: int = 5, interval: str = None) -> None:
        self.prices = PriceHistory(self.symbol, days_back, interval).download()

    def populate_options(self, max_number: int = None) -> None:
        self.options = StockOptions(self.symbol, max_number).download()

    def __hash__(self) -> int:
        return hash(self.symbol)

    def __str__(self) -> str:
        return self.symbol
