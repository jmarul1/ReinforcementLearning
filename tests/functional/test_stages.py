from datetime import datetime, timedelta
from math import isclose
from pandas import DataFrame
from stk_guide.entities.stock import Stock
from stk_guide.entities.stocks import Stocks
from stk_guide.ml.models.model import Model
from stk_guide.ml.models.sequence import SequenceModel
from stk_guide.pipeline.stages.collecting import Collector
from stk_guide.pipeline.context import Context
from stk_guide.pipeline.stages.predicting import PricePredictor
from stk_guide.pipeline.stages.training import ClosePriceTrainer


def test_collector(context_sample1: Context) -> None:
    collector = Collector()
    collector(context_sample1, years_back=0.1)
    assert isclose(collector._years_back, 0.1)  # pylint: disable = protected-access
    assert len(context_sample1.stocks[0].prices) > 0


def test_trainer(context_sample2: Context) -> None:
    model = SequenceModel(epochs=1)
    ClosePriceTrainer(model)(context_sample2)
    assert isinstance(context_sample2.models, dict)
    for stock in context_sample2.stocks:
        assert isinstance(context_sample2.models[stock], Model)
        assert hasattr(context_sample2.models[stock], "_apimodel")


def test_price_predictor(context_sample3: Context) -> None:
    features = DataFrame({"datetime": [datetime.now() + timedelta(days=id) for id in range(3)]})
    PricePredictor()(context_sample3, future_space=features)
    assert len(context_sample3.predictions) == 1
    for pred in context_sample3.predictions:
        df = pred.prices.to_frame()
        assert len(df) == 3
