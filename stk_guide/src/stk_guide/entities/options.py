from numbers import Number
from enum import StrEnum, auto
from attrs import define, field
from pandas import DataFrame
from numpy import mean
from ..ml.encoding.algorithms import MinMaxCoder
from ..ml.encoding.encoder import Encoder


class OptionsEnum(StrEnum):
    EXPIRATION = auto()
    BID = auto()
    ASK = auto()
    IMPLIEDVOLATILITY = "impliedVolatility"
    OPENINTEREST = "openInterest"
    PERCENTCHANGE = "percentChange"
    VOLUME = auto()
    PROJECTED_PRICE_v0 = auto()
    PROJECTED_PRICE_v1 = auto()
    STRIKE = auto()
    SCORES = auto()


@define
class Options:
    calls: DataFrame = field(default=None)
    puts: DataFrame = field(default=None)

    def sumarize_calls(self, weights: int | dict[str, int] = 1) -> DataFrame:
        keys_weights = self._keys_weights(weights)
        return DataFrame(self.summarize_data(calls, keys_weights) for _, calls in self.calls.groupby(OptionsEnum.EXPIRATION.value))

    def sumarize_puts(self, weights: int | dict[str, int] = 1) -> DataFrame:
        keys_weights = self._keys_weights(weights)
        return DataFrame(self.summarize_data(puts, keys_weights) for _, puts in self.puts.groupby(OptionsEnum.EXPIRATION.value))

    @staticmethod
    def summarize_data(options_data: DataFrame, keys_weights: dict[str, int]) -> dict[str, Number | str]:
        _data = {}
        keys, weights = list(keys_weights), list(keys_weights.values())
        iscores = Encoder(feature_scalers={name: MinMaxCoder() for name in keys}).fit_transform(options_data.loc[:, keys])
        iscores[OptionsEnum.IMPLIEDVOLATILITY.value] = 1 - iscores[OptionsEnum.IMPLIEDVOLATILITY.value]
        scores = (iscores * weights).prod(axis=1)
        for name, values in options_data.items():
            if isinstance(values.iloc[0], Number):
                _data[name] = mean(values)
            else:
                _data[name] = values.iloc[0]
        _data[OptionsEnum.PROJECTED_PRICE_v0.value] = (options_data[OptionsEnum.STRIKE.value] * scores).sum() / scores.sum()
        strikes_scored = DataFrame(
            {
                OptionsEnum.PROJECTED_PRICE_v1: options_data[OptionsEnum.STRIKE.value] + options_data[OptionsEnum.ASK.value],
                OptionsEnum.SCORES: scores,
            }
        )
        ranked_strikes = strikes_scored.sort_values(OptionsEnum.SCORES, ascending=False)
        _data[OptionsEnum.PROJECTED_PRICE_v1.value] = ranked_strikes[OptionsEnum.PROJECTED_PRICE_v1].iloc[0]
        return _data

    def _keys_weights(self, weights: int | dict[str, int]) -> dict[str, int]:
        keys = [
            OptionsEnum.BID.value,
            OptionsEnum.ASK.value,
            OptionsEnum.OPENINTEREST.value,
            OptionsEnum.VOLUME.value,
            OptionsEnum.IMPLIEDVOLATILITY.value,
            OptionsEnum.PERCENTCHANGE.value,
        ]
        if isinstance(weights, dict):
            for key in weights:
                if key not in keys:
                    raise ValueError(f"Provided weights are wrong: {weights}")
        return {key: (weights[key] if isinstance(weights, dict) and key in weights else 1) for key in keys}
