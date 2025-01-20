from attrs import define, field
from click import MissingParameter
from pandas import DataFrame
from ...entities.prediction import Prediction
from ...entities.prices import Prices
from ..context import Context
from ..decorators import PrePostExecution
from .stage import Stage, StageInputs


@define
class Predictor(Stage):
    _future_space: DataFrame = field(init=False)

    @PrePostExecution.stage
    def __call__(self, context: Context, **kwargs: StageInputs.kwargs) -> None:
        raise NotImplementedError

    def _init(self, **kwargs: StageInputs.kwargs) -> None:
        if "future_space" not in kwargs:
            raise MissingParameter("future_space")
        self._future_space = kwargs["future_space"]


class PricePredictor(Predictor):
    @PrePostExecution.stage
    def __call__(self, context: Context, **kwargs: StageInputs.kwargs) -> None:
        for stock, model in context.models.items():
            prediction = Prediction(stock)
            price_preds = model.predict(self._future_space)
            for future_date, price_pred in zip(self._future_space.iloc[:, 0], price_preds):
                prediction.prices[future_date] = {"Close": price_pred}
            context.predictions.append(prediction)
