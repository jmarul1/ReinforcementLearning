from datetime import datetime
from numbers import Number
from attrs import define
from pandas import DataFrame


PriceEntry = dict[str, float]


class Prices(dict):
    def __init__(self, iterable: dict[datetime, PriceEntry] = None) -> None:
        if iterable is None:
            iterable = {}
        self._validate(iterable)
        super().__init__(iterable)

    def _validate(self, iterable: dict[datetime, PriceEntry] = None) -> None:
        for key, val in iterable.items():
            if not isinstance(key, datetime):
                raise ValueError("Keys must be datetime objects")
            if not isinstance(val, dict):
                raise ValueError("Price must be a dict")
            for pkey, pval in val.items():
                if not isinstance(pkey, str):
                    raise ValueError("Price Key must be a str")
                if not isinstance(pval, Number):
                    raise ValueError("Price value must be a number")

    def __setitem__(self, key: datetime, value: PriceEntry) -> None:
        self._validate({key: value})
        return super().__setitem__(key, value)

    def to_frame(self) -> DataFrame:
        return DataFrame(self).transpose()
