from functools import singledispatch, singledispatchmethod
from numbers import Number
from datetime import datetime

from pandas import DataFrame, Series

NativeDataType = datetime | str | bool | Number


class DataType:
    @staticmethod
    def get_type(test: NativeDataType | list | tuple | DataFrame | Series) -> NativeDataType | list[NativeDataType]:
        return DataType()._get_type(test)  # pylint: disable = protected-access

    def _findout(self, test: NativeDataType) -> NativeDataType:
        for check in [Number, str, bool, datetime]:
            if isinstance(test, check):
                return check
        raise ValueError(f"Unknown data type: {test}")

    @singledispatchmethod
    def _get_type(self, test: NativeDataType | list | tuple | DataFrame | Series) -> list[NativeDataType]:
        raise NotImplementedError

    @_get_type.register
    def _(self, test: NativeDataType) -> NativeDataType:
        return self._findout(test)

    @_get_type.register
    def _(self, test: DataFrame) -> list[NativeDataType]:
        return [self._findout(itest) for itest in test.iloc[0, :]]

    @_get_type.register
    def _(self, test: list | tuple | Series) -> list[NativeDataType]:
        return [self._findout(itest) for itest in test]
