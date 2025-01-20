from attrs import define, field
from pandas import DataFrame, Series
from sklearn.ensemble import GradientBoostingRegressor
from .model import Model
from ..encoding.encoder import Encoder
from ..encoding.algorithms import MinMaxCoder
from ..utils.data_utils import DataType


@define
class GbrModel(Model):
    _apimodel: GradientBoostingRegressor = field(init=False)

    def train(self, features: DataFrame, labels: Series) -> None:
        self._features_types = DataType.get_type(features)
        _features = self.preprocessor(features)
        self._apimodel = GradientBoostingRegressor()
        self._apimodel.fit(_features, labels)
        print(_features)
