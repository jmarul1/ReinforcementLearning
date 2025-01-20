from attrs import define, field
from pandas import DataFrame, Series
from keras.models import Sequential  # pylint: disable = import-error
from keras.layers import Dense, LSTM  # pylint: disable = import-error
from .model import Model
from ..utils.data_utils import DataType


@define
class SequenceModel(Model):
    epochs: int = field(default=100, kw_only=True)
    batch_size: int = field(default=1, kw_only=True)
    _apimodel: Sequential = field(init=False)

    def train(self, features: DataFrame, labels: Series) -> None:
        self._features_types = DataType.get_type(features)
        _features = self.preprocessor(features)
        self._apimodel = Sequential()
        self._apimodel.add(LSTM(50, return_sequences=True, input_shape=(features.shape[1], 1)))
        self._apimodel.add(LSTM(50, return_sequences=False, input_shape=(features.shape[1], 1)))
        self._apimodel.add(Dense(25))
        self._apimodel.add(Dense(1))
        self._apimodel.compile(optimizer="adam", loss="mean_squared_error")
        self._apimodel.fit(_features, labels, batch_size=self.batch_size, epochs=self.epochs)
