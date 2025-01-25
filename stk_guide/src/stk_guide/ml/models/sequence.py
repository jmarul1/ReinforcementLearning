from attrs import define, field
from pandas import DataFrame, Series
from keras import Sequential, layers, optimizers, Input
from .model import Model
from ..utils.data_utils import DataType


@define
class SequenceModel(Model):
    epochs: int = field(default=100, kw_only=True)
    batch_size: int = field(default=1, kw_only=True)
    lr: float = field(default=0.001, kw_only=True)
    _apimodel: Sequential = field(init=False)

    def train(self, features: DataFrame, labels: Series) -> None:
        self._features_types = DataType.get_type(features)
        _features = self.preprocessor(features)
        self._apimodel = Sequential()
        self._apimodel.add(Input(shape=(features.shape[1], 1)))
        self._apimodel.add(layers.LSTM(50, return_sequences=True))
        self._apimodel.add(layers.LSTM(50, return_sequences=False))
        self._apimodel.add(layers.Dense(25, activation="relu"))
        self._apimodel.add(layers.Dense(1))
        optimizer = optimizers.Adam(learning_rate=self.lr)
        self._apimodel.compile(optimizer=optimizer, loss="mean_squared_error")
        self._apimodel.fit(_features, labels, batch_size=self.batch_size, epochs=self.epochs)

    def save(self, prefix_path: str) -> bool:
        return self._apimodel.save(prefix_path + ".keras")
