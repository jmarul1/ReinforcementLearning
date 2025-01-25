from attrs import define
from pandas import DataFrame
from ...entities.prices import PricesEnum
from ..decorators import PrePostExecution
from ..context import Context
from ...ml.models.model import Model
from .stage import Stage, StageInputs


@define
class Trainer(Stage):
    model: Model

    @PrePostExecution.stage
    def __call__(self, context: Context, **kwargs: StageInputs.kwargs) -> None:
        raise NotImplementedError

    def _init(self, **kwargs: StageInputs.kwargs) -> None:
        pass


class ClosePriceTrainer(Trainer):
    @PrePostExecution.stage
    def __call__(self, context: Context) -> None:
        labels = DataFrame(context.stock.prices).transpose().Close
        _data = labels.reset_index().rename({"index": PricesEnum.DATETIME.value}, axis=1)
        features = _data.datetime.to_frame()
        self.model.preprocessor = context.preprocessor
        self.model.train(features, labels)
        context.model = self.model


class ClosePriceOptionsTrainer(Trainer):
    @PrePostExecution.stage
    def __call__(self, context: Context) -> None:
        labels = DataFrame(context.stock.prices).transpose().Close
        _data = labels.reset_index().rename({"index": PricesEnum.DATETIME.value}, axis=1)
        features = _data.datetime.to_frame()
        self.model.preprocessor = context.preprocessor
        self.model.train(features, labels)
        context.model = self.model
