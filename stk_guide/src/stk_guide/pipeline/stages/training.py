from attrs import define, field
from pandas import DataFrame
from .stage import Stage, StageInputs
from ..decorators import PrePostExecution
from ..context import Context
from ...ml.models.model import Model


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
        for stock in context.stocks:
            model_inst = self.model.clone_reset()
            labels = DataFrame(stock.prices).transpose().Close
            _data = labels.reset_index().rename({"index": "datetime"}, axis=1)
            features = _data.datetime.to_frame()
            model_inst.train(features, labels)
            context.models[stock] = model_inst
