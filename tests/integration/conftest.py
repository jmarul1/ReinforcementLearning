import pytest
from stk_guide.entities.stock import Stock
from stk_guide.entities.stocks import Stocks
from stk_guide.pipeline.context import Context
from stk_guide.pipeline.pipeline import Pipeline
from stk_guide.pipeline.stages.collecting import PriceCollector


@pytest.fixture
def context_sample() -> Context:
    return Context(Stock("AAPL", "Apple"))


@pytest.fixture
def pipeline_sample(context_sample: Stock) -> Pipeline:  # pylint: disable = redefined-outer-name
    pl = Pipeline(context_sample)
    coll = PriceCollector()
    pl.add(coll, years_back=0.01)
    return pl
