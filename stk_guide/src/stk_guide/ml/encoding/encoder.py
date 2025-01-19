from datetime import datetime
from inspect import signature
from numbers import Number
from typing import Self
from attrs import define, field
from pandas import DataFrame, Series
from ..utils.reset_utils import ResetClone
from ..utils.data_utils import NativeDataType
from .algorithms import CoderType, IdentityCoder, DatetimeCoder, OneHotCoder, OrdinalCoder


@define
class Encoder:
    custom_encoding: dict[str, CoderType] = field(default=None)
    _default_encoders: dict[CoderType, NativeDataType] = field(init=False)
    _active_coders: dict[str, CoderType] = field(init=False, factory=dict)

    def __attrs_post_init__(self) -> None:
        self._default_encoders = {
            DatetimeCoder: datetime,
            OneHotCoder: str,
            IdentityCoder: (float, int),
            OrdinalCoder: bool,
        }

    def __call__(self, data: DataFrame) -> DataFrame:
        encoded_data = {}
        for colname, values in data.items():
            if colname not in self._active_coders:
                raise ValueError(f"No coder found for: {colname}")
            coder = self._active_coders[colname]
            encoded_data[colname] = coder.code(values)
        return DataFrame(encoded_data)

    def fit(self, data: DataFrame) -> None:
        for colname, values in data.items():
            if self.custom_encoding and colname in self.custom_encoding:
                encoder = self.custom_encoding[colname]
            else:
                encoder = self.get_default(values)
            self._active_coders[colname] = encoder.fit(values)

    def fit_transform(self, data: DataFrame) -> DataFrame:
        self.fit(data)
        return self(data)

    def get_default(self, values: Series) -> CoderType:
        encoder = IdentityCoder
        for iencoder, ntype in self._default_encoders.items():
            if isinstance(values[0], ntype):
                encoder = iencoder
                break
        return encoder()

    def clone_reset(self) -> Self:
        return ResetClone().clone_reset(self)
