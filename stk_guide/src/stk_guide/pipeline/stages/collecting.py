from attrs import define, field
from click import MissingParameter
from .stage import Stage, StageInputs
from ..decorators import PrePostExecution
from ..context import Context


@define
class Collector(Stage):
    @PrePostExecution.stage
    def __call__(self, context: Context, **kwargs: StageInputs.kwargs) -> None:
        raise NotImplementedError


@define
class PriceCollector(Collector):
    _days_back: int | float = field(init=False)
    _interval: str = field(init=False)

    @PrePostExecution.stage
    def __call__(self, context: Context, **kwargs: StageInputs.kwargs) -> None:
        context.stock.populate_prices(self._days_back, self._interval)

    def _init(self, **kwargs: StageInputs.kwargs) -> None:
        if "days_back" not in kwargs:
            raise MissingParameter("days_back")
        if "interval" in kwargs:
            self._interval = kwargs["interval"]
        self._days_back = kwargs["days_back"]
