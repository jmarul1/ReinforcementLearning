from datetime import datetime
from enum import StrEnum, auto
from attrs import define
from pandas import DataFrame


class RatingEnum(StrEnum):
    BUY = auto()
    HOLD = auto()
    SELL = auto()


@define
class Rating:
    date: datetime
    buy: int
    hold: int
    sell: int

    def to_frame(self, index: list[str] = None) -> DataFrame:
        if index is None:
            index = [0]
        cols = ["date", "buy", "hold", "sell"]
        return DataFrame([[self.date, self.buy, self.hold, self.sell]], columns=cols, index=index)
