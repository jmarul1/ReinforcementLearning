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
    _years_back: int | float = field(init=False)

    @PrePostExecution.stage
    def __call__(self, context: Context, **kwargs: StageInputs.kwargs) -> None:
        context.stock.populate_prices(self._years_back)

    def _init(self, **kwargs: StageInputs.kwargs) -> None:
        if "years_back" not in kwargs:
            raise MissingParameter("years_back")
        self._years_back = kwargs["years_back"]
