import pytest
from stk_guide.entities.stock import Stock
from stk_guide.entities.stocks import Stocks
from stk_guide.ml.models.gbr import GbrModel
from stk_guide.pipeline.pipeline_stages import PipelineStages
from stk_guide.pipeline.stages.collecting import Collector
from stk_guide.pipeline.stages.predicting import PricePredictor
from stk_guide.pipeline.stages.training import ClosePriceTrainer
from stk_guide.strategies.historic_price import HistoricPrice


@pytest.fixture
def pipeline_stages() -> PipelineStages:
    return PipelineStages(collector=Collector(), trainer=ClosePriceTrainer(GbrModel()), predictor=PricePredictor())


def test_historic_price_flow(pipeline_stages: PipelineStages) -> None:  # pylint: disable=redefined-outer-name
    hp = HistoricPrice(pipeline_stages)
    stocks = Stocks([Stock("AAPL", "Apple"), Stock("INTC", "Intel")])
    preds = hp(stocks, years_back=0.01, days_fwd=2)
    assert len(preds) == 2
    for pred in preds:
        df = pred.prices.to_frame()
        assert len(df) == 2
