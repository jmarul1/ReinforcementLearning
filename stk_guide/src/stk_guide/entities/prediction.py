from attrs import define, field
from .stock import Stock
from .prices import Prices


@define
class Prediction:
    stock: Stock = field(default=None)
    recommendation: str = field(default=None)
    prices: Prices = field(factory=Prices)
