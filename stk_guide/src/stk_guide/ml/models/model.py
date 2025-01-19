from abc import abstractmethod
from inspect import signature
from typing import Self
from attrs import asdict, define, field
from pandas import DataFrame, Series, concat
from ..encoding.encoder import Encoder
from ..encoding.algorithms import MinMaxCoder
from ..utils.reset_utils import ResetClone
from ..utils.data_utils import DataType, NativeDataType


@define
class Model:
    preprocessor: Encoder = field(default=None, kw_only=True)
    feature_encoder: Encoder = field(factory=Encoder, kw_only=True)
    _features_types: Series = field(init=False)

    def _fit_preprocessors(self, features: DataFrame) -> None:
        efeatures = self.feature_encoder.fit_transform(features)
        _efeatures = self.expand_one_hot_features(efeatures)
        if self.preprocessor is None:
            self.setup_preprocessor(_efeatures)
        self.preprocessor.fit(_efeatures)

    def _preprocess(self, features: DataFrame) -> DataFrame:
        efeatures = self.feature_encoder(features)
        _efeatures = self.expand_one_hot_features(efeatures)
        return self.preprocessor(_efeatures)

    def predict(self, features: DataFrame) -> Series:
        if not self._check_features_types(features):
            raise ValueError("Predicting features shape/types must match that of training")
        _features = self._preprocess(features)
        preds = self._apimodel.predict(_features)
        return Series(preds.squeeze().reshape(-1), name=str(self))

    def setup_preprocessor(self, features: DataFrame) -> None:
        self.preprocessor = Encoder(custom_encoding={colname: MinMaxCoder() for colname in features})

    def clone_reset(self) -> Self:
        return ResetClone().clone_reset(self)

    def data_type(self, test: NativeDataType) -> NativeDataType:
        return DataType.get_type(test)

    def __str__(self) -> str:
        return str(self.__class__)

    def _check_features_types(self, features: DataFrame) -> bool:
        if not len(self._features_types) == features.shape[1]:
            return False
        for orig, test in zip(self._features_types, DataType.get_type(features)):
            if orig != test:
                return False
        return True

    @abstractmethod
    def train(self, features: DataFrame, labels: Series) -> None:
        raise NotImplementedError

    @staticmethod
    def expand_one_hot_features(features: DataFrame) -> DataFrame:
        expandable = [isinstance(fvalue, list) for fvalue in features.iloc[0]]
        features_expanded = []
        for idx, colname in enumerate(features):
            new_cols = features[colname]
            if expandable[idx]:
                new_colnames = [f"{cid}.{colname}" for cid, _ in enumerate(new_cols.iloc[0])]
                new_cols = DataFrame(new_cols.to_list(), columns=new_colnames)
            features_expanded.append(new_cols)
        return concat(features_expanded, axis=1)
