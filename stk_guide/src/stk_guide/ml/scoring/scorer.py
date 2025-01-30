from abc import ABC, abstractmethod
from attrs import define, field
from pandas import DataFrame, Series
from ..encoding.encoder import Encoder
from ..encoding.algorithms import MinMaxCoder
from ...entities.rating import RatingEnum


class Scorer(ABC):
    @abstractmethod
    def __call__(self, data: DataFrame) -> Series:
        pass


@define
class RatingsScorer(Scorer):
    hold_weight: float = field(default=0.5)

    def __call__(self, data: DataFrame) -> Series:
        _data = data.loc[:, [RatingEnum.BUY, RatingEnum.SELL, RatingEnum.HOLD]]
        df = Encoder(feature_scalers=MinMaxCoder()).fit_transform(_data)
        buy = 1 - df[RatingEnum.BUY]
        hold = df[RatingEnum.HOLD] * self.hold_weight
        scores = buy + hold + df[RatingEnum.SELL]
        nscores = Encoder(feature_scalers=MinMaxCoder()).fit_transform(scores.to_frame()).iloc[:, 0]
        nscores.name = "scores"
        return nscores
