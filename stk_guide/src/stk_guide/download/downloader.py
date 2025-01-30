from abc import ABC, abstractmethod
from os import environ
from typing import Any
from datetime import datetime, timedelta, date
from dateutil.tz import gettz
from attrs import define, field
from pandas import concat
from yfinance import Ticker
from robin_stocks.robinhood import get_ratings
from finnhub import Client
from ..entities.prices import Prices
from ..entities.options import OptionsEnum, Options
from ..entities.rating import Rating
from .download_enum import FinhubEnum, RobinhoodEnum, TimeZone

OutputType = dict[datetime, dict[str, float]] | dict[str, Any]


@define
class Downloader(ABC):
    symbol: str

    @abstractmethod
    def download(self) -> Prices | Options:
        raise NotImplementedError


@define
class StockInfo(Downloader):
    def download(self) -> dict[str, Any]:
        return Ticker(self.symbol).info


@define
class PriceHistory(Downloader):
    days_back: int | float
    interval: str = field(default="1d")

    def download(self) -> Prices:
        tz = gettz(TimeZone.DEFAULT.value)
        start = datetime.now(tz) - timedelta(days=int(self.days_back))
        tic = Ticker(self.symbol)
        df = tic.history(start=start, interval=self.interval)
        return Prices(df.to_dict("index"))


@define
class StockOptions(Downloader):
    max_number: int = field(default=None)

    def __atrs_post_init__(self) -> None:
        if self.max_number is None:
            self.max_number = -1

    def download(self) -> Options:
        tic = Ticker(self.symbol)
        calls, puts = [], []
        for option in tic.options[: self.max_number]:
            tic_options = tic.option_chain(option)
            _calls, _puts = tic_options.calls, tic_options.puts
            _calls[OptionsEnum.EXPIRATION] = datetime.strptime(option, "%Y-%m-%d").date()
            _puts[OptionsEnum.EXPIRATION] = datetime.strptime(option, "%Y-%m-%d").date()
            calls.append(tic_options.calls)
            puts.append(tic_options.puts)
        return Options(concat(calls), concat(puts))


@define
class RobinhoodRatings(Downloader):
    def download(self) -> list[Rating]:
        dt = get_ratings(self.symbol)
        return [self.robinhood_transform(dt)]

    def robinhood_transform(self, entry: dict) -> Rating:
        date_str = entry[RobinhoodEnum.PUBLISHED]
        _date = datetime.strptime(date_str.split("T")[0], "%Y-%m-%d").date() if date_str is not None else date.today()
        for name, value in entry[RobinhoodEnum.SUMMARY].items():
            match name:
                case RobinhoodEnum.BUY:
                    buy = value
                case RobinhoodEnum.SELL:
                    sell = value
                case RobinhoodEnum.HOLD:
                    hold = value
                case _:
                    pass
        return Rating(_date, buy, hold, sell)


@define
class FinhubRating(Downloader):
    _client: Client = field(init=False)

    def __attrs_post_init__(self) -> None:
        self._client = Client(api_key=environ["FINHUB_TOKEN"])

    def download(self) -> list[Rating]:
        lst = self._client.recommendation_trends(self.symbol)
        return [self.finhub_transform(dt) for dt in lst]

    def finhub_transform(self, entry: dict) -> Rating:
        date_str = entry[FinhubEnum.PUBLISHED]
        _date = datetime.strptime(date_str, "%Y-%m-%d").date() if date_str is not None else date.today()
        buy = sell = 0
        for name, value in entry.items():
            match name:
                case FinhubEnum.STRONG_BUY:
                    buy += value * 1.25
                case FinhubEnum.STRONG_SELL:
                    sell += value * 1.25
                case FinhubEnum.BUY:
                    buy += value
                case FinhubEnum.SELL:
                    sell += value
                case FinhubEnum.HOLD:
                    hold = value
                case _:
                    pass
        return Rating(_date, buy, hold, sell)
