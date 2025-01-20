from attrs import define, field
from ..ml.encoding.encoder import Encoder
from ..ml.models.model import Model
from ..entities.stock import Stock
from ..entities.prediction import Prediction


@define
class Context:
    stock: Stock = field(default=None)
    preprocessor: Encoder = field(default=None)
    model: Model = field(default=None)
    prediction: Prediction = field(default=None)
