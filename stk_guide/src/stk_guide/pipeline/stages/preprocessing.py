from attrs import define, field
from click import MissingParameter
from .stage import Stage, StageInputs
from ...ml.encoding.encoder import Encoder
from ..decorators import PrePostExecution
from ..context import Context


@define
class Preprocessor(Stage):
    encoder: Encoder = field(factory=Encoder)

    @PrePostExecution.stage
    def __call__(self, context: Context, **kwargs: StageInputs.kwargs) -> None:
        raise NotImplementedError

    def _init(self, **kwargs: StageInputs.kwargs) -> None:
        pass


class PricePreprocessor(Preprocessor):
    @PrePostExecution.stage
    def __call__(self, context: Context, **kwargs: StageInputs.kwargs) -> None:
        context.preprocessor = self.encoder.fit(context.stock.prices.features())
