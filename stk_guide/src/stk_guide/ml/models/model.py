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
    preprocessor: Encoder = field(factory=Encoder, kw_only=True)
    _features_types: Series = field(init=False)

    def predict(self, features: DataFrame) -> Series:
        if not self._check_features_types(features):
            raise ValueError("Predicting features shape/types must match that of training")
        _features = self.preprocessor(features)
        preds = self._apimodel.predict(_features)
        print(_features)
        return Series(preds.squeeze().reshape(-1), name=str(self))

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
