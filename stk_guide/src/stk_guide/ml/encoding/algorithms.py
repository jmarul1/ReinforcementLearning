from typing import Any, Self
from attrs import define, field
from numpy import array
from sklearn.preprocessing import MinMaxScaler, OneHotEncoder, OrdinalEncoder
from ..utils.reset_utils import ResetClone
from ..utils.data_utils import NativeDataType


EncoderApi = MinMaxScaler | OneHotEncoder | OrdinalEncoder


@define
class CoderType:
    options: dict[str, Any] = field(factory=dict)
    api: EncoderApi = field(init=False)

    def fit(self, data: list[NativeDataType]) -> Self:
        _data = array(data).reshape(-1, 1)
        self.api.fit(_data)
        return self

    def code(self, data: list[NativeDataType]) -> list[float] | list[list[float]]:
        _data = array(data).reshape(-1, 1)
        edata = self.api.transform(_data)
        return edata.squeeze().tolist()

    def fit_code(self, data: list[NativeDataType]) -> list[float] | list[list[float]]:
        self.fit(data)
        return self.code(data)

    def clone_reset(self) -> Self:
        return ResetClone().clone_reset(self)


@define
class OrdinalCoder(CoderType):
    def __attrs_post_init__(self) -> None:
        self.api = OrdinalEncoder(**self.options)


@define
class MinMaxCoder(CoderType):
    def __attrs_post_init__(self) -> None:
        self.api = MinMaxScaler(**self.options)


@define
class IdentityCoder(CoderType):
    def fit(self, data: list[NativeDataType]) -> Self:
        return self

    def code(self, data: list[float]) -> list[float]:
        return data


@define
class DatetimeCoder(CoderType):
    def fit(self, data: list[NativeDataType]) -> Self:
        return self

    def code(self, data: list) -> list:
        return [idata.timestamp() for idata in data]


@define
class OneHotCoder(CoderType):
    def __attrs_post_init__(self) -> None:
        self.api = OneHotEncoder(**self.options)

    def code(self, data: list[NativeDataType]) -> list[list[float]]:
        _data = array(data).reshape(-1, 1)
        edata = self.api.transform(_data)
        return edata.toarray().tolist()
