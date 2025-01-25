import pytest
from stk_guide.entities.prediction import Prediction
from stk_guide.entities.stock import Stock
from stk_guide.entities.stocks import Stocks
from stk_guide.ml.models.gbr import GbrModel
from stk_guide.pipeline.context import Context
from stk_guide.pipeline.pipeline_stages import PipelineStages
from stk_guide.pipeline.stages.collecting import PriceCollector
from stk_guide.pipeline.stages.predicting import PricePredictor
from stk_guide.pipeline.stages.preprocessing import PricePreprocessor
from stk_guide.pipeline.stages.training import ClosePriceTrainer
from stk_guide.strategies.historic_price import HistoricPrice


@pytest.fixture
def pipeline_stages() -> PipelineStages:
    return PipelineStages(
        collector=PriceCollector(), preprocessor=PricePreprocessor(), trainer=ClosePriceTrainer(GbrModel()), predictor=PricePredictor()
    )


def test_historic_price_flow(pipeline_stages: PipelineStages) -> None:  # pylint: disable=redefined-outer-name
    hp = HistoricPrice(pipeline_stages)
    stock = Stock("AAPL", "Apple")
    context = hp(stock, years_back=0.1, days_fwd=2)
    assert isinstance(context, Context)
    assert isinstance(context.prediction, Prediction)
    df = context.prediction.prices.to_frame()
    assert len(df) == 2
