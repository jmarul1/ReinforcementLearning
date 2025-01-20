from datetime import datetime, timedelta
from math import isclose
from pandas import DataFrame
from stk_guide.entities.prediction import Prediction
from stk_guide.entities.prices import PricesEnum
from stk_guide.entities.stock import Stock
from stk_guide.entities.stocks import Stocks
from stk_guide.ml.encoding.encoder import Encoder
from stk_guide.ml.models.model import Model
from stk_guide.ml.models.sequence import SequenceModel
from stk_guide.pipeline.stages.collecting import PriceCollector
from stk_guide.pipeline.context import Context
from stk_guide.pipeline.stages.predicting import PricePredictor
from stk_guide.pipeline.stages.preprocessing import PricePreprocessor
from stk_guide.pipeline.stages.training import ClosePriceTrainer


def test_collector(context_sample1: Context) -> None:
    collector = PriceCollector()
    collector(context_sample1, years_back=0.1)
    assert isclose(collector._years_back, 0.1)  # pylint: disable = protected-access
    assert len(context_sample1.stock.prices) > 0


def test_preprocessor(context_sample2: Context) -> None:
    preprocessor = PricePreprocessor()
    preprocessor(context_sample2)
    assert isinstance(context_sample2.preprocessor, Encoder)
    assert len(context_sample2.preprocessor.feature_encoders) == 1
    assert len(context_sample2.preprocessor.feature_scalers) == 1


def test_trainer(context_sample3: Context) -> None:
    model = SequenceModel(epochs=1)
    ClosePriceTrainer(model)(context_sample3)
    assert isinstance(context_sample3.model, Model)
    assert hasattr(context_sample3.model, "_apimodel")


def test_price_predictor(context_sample4: Context) -> None:
    features = DataFrame({PricesEnum.DATETIME.value: [datetime.now() + timedelta(days=id) for id in range(3)]})
    PricePredictor()(context_sample4, future_space=features)
    assert isinstance(context_sample4.prediction, Prediction)
    assert len(context_sample4.prediction.prices.to_frame()) == 3
