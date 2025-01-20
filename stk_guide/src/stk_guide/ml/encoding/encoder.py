from datetime import datetime
from typing import Self
from attrs import define, field
from pandas import DataFrame, Series, concat
from ..utils.reset_utils import ResetClone
from ..utils.data_utils import NativeDataType
from .algorithms import CoderType, IdentityCoder, DatetimeCoder, OneHotCoder, OrdinalCoder


@define
class Encoder:
    feature_encoders: dict[str, CoderType] = field(factory=dict)
    feature_scalers: dict[str, CoderType] = field(factory=dict)
    _default_encoders: dict[CoderType, NativeDataType] = field(init=False)
    _fitted: bool = field(default=False, init=False)

    def __attrs_post_init__(self) -> None:
        self._default_encoders = {DatetimeCoder: datetime, OneHotCoder: str, IdentityCoder: (float, int), OrdinalCoder: bool}

    def __call__(self, data: DataFrame) -> DataFrame:
        if not self._fitted:
            raise UnboundLocalError("Encoder.fit must be called before")
        for colname in list(data):
            if (colname not in self.feature_encoders) or (colname not in self.feature_scalers):
                raise ValueError(f"No encoder instructions for {colname}")
        encoded_data = {}
        for colname, values in data.items():
            edata = self.feature_encoders[colname].code(values)
            for _colname, _edata in self.expand_onehot(DataFrame({colname: edata})).items():
                encoded_data[_colname] = self.feature_scalers[_colname].fit_code(_edata)
        return DataFrame(encoded_data)

    def fit(self, data: DataFrame) -> Self:
        for colname, values in data.items():
            if colname not in self.feature_encoders:
                self.feature_encoders[colname] = self.get_default(values)
            edata = self.feature_encoders[colname].fit_code(values)
            if colname not in self.feature_scalers:
                self.feature_scalers[colname] = IdentityCoder()
            for _colname, _edata in self.expand_onehot(DataFrame({colname: edata})).items():
                scaler = self.feature_scalers[colname].clone_reset()
                self.feature_scalers[_colname] = scaler.fit(_edata)
        self._fitted = True
        return self

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
        return ResetClone().clone_reset(self, dont_resets=["custom_encoding"])

    @staticmethod
    def expand_onehot(features: DataFrame) -> DataFrame:
        expandable = [isinstance(fvalue, list) for fvalue in features.iloc[0]]
        features_expanded = []
        for idx, colname in enumerate(features):
            new_cols = features[colname]
            if expandable[idx]:
                new_colnames = [f"{cid}.{colname}" for cid, _ in enumerate(new_cols.iloc[0])]
                new_cols = DataFrame(new_cols.to_list(), columns=new_colnames)
            features_expanded.append(new_cols)
        return concat(features_expanded, axis=1)
