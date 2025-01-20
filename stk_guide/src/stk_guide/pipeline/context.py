from copy import deepcopy
from typing import Self
from attrs import define, field
from ..ml.models.model import Model
from ..entities.stocks import Stocks
from ..entities.stock import Stock
from ..entities.prediction import Prediction


@define
class Context:
    stocks: Stocks = field(default=None)
    models: dict[Stock, Model] = field(factory=dict)
    predictions: list[Prediction] = field(factory=list)
