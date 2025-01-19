from collections.abc import Iterable  # pylint: disable = import-error
from .stock import Stock


class Stocks(list):
    """Contains list[Stock]"""

    def __init__(self, iterable: Iterable[Stock] = None) -> None:
        if iterable is None:
            iterable = []
        for item in iterable:
            self.append(item)

    def append(self, item: Stock) -> None:
        self._validate(item)
        if item not in self:
            super().append(item)

    def _validate(self, item: Stock) -> None:
        if not isinstance(item, Stock):
            raise ValueError(f"Must belong to class Stock: {item}")

    def __contains__(self, stock: Stock) -> bool:
        for item in self:
            if item == stock:
                return True
        return False
