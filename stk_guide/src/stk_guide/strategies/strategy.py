from abc import abstractmethod
from pandas import DataFrame
from ..entities.stocks import Stocks


class Strategy:
    @abstractmethod
    def __call__(self, stocks: Stocks) -> DataFrame:
        raise NotImplementedError
