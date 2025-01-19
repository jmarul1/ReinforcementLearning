from datetime import datetime, timedelta
from pandas import DataFrame, MultiIndex
import pytest
from stk_guide.entities.stock import Stock
from stk_guide.entities.stocks import Stocks
from stk_guide.ml.models.gbr import GbrModel
from stk_guide.ml.models.model import Model
from stk_guide.ml.models.sequence import SequenceModel
from stk_guide.pipeline.context import Context
from stk_guide.pipeline.stages.collecting import Collector
from stk_guide.pipeline.stages.training import ClosePriceTrainer


@pytest.fixture
def stock_sample() -> Stock:
    return Stock("AAPL", "Apple")


@pytest.fixture
def context_sample1(stock_sample: Stock) -> Context:  # pylint: disable = redefined-outer-name
    return Context(Stocks([stock_sample]))


@pytest.fixture
def context_sample2(context_sample1: Context) -> Context:  # pylint: disable = redefined-outer-name
    Collector()(context_sample1, years_back=0.05)
    return context_sample1


@pytest.fixture
def context_sample3(context_sample2: Context) -> Context:  # pylint: disable = redefined-outer-name
    ClosePriceTrainer(GbrModel())(context_sample2)
    return context_sample2


@pytest.fixture
def int_dataset() -> DataFrame:
    df = DataFrame({"i1": [1, 2, 3, 4, 5], "i2": [5, 4, 3, 2, 1], "o1": [100, 200, 300, 400, 500]})
    df.columns = MultiIndex.from_arrays([["Features", "Features", "Labels"], df.columns.values])
    return df


@pytest.fixture
def date_dataset() -> DataFrame:
    start = datetime.now()
    times = [(start + timedelta(days=idx)) for idx in range(5)]
    df = DataFrame({"i1": times, "o1": [100, 200, 300, 400, 500]})
    df.columns = MultiIndex.from_arrays([["Features", "Labels"], df.columns.values])
    return df


@pytest.fixture
def str_dataset() -> DataFrame:
    df = DataFrame({"i1": ["a", "b", "c", "d", "e"], "i2": ["a", "b", "c", "d", "e"], "o1": [100, 200, 300, 400, 500]})
    df.columns = MultiIndex.from_arrays([["Features", "Features", "Labels"], df.columns.values])
    return df


@pytest.fixture
def datasets_lookup(
    int_dataset: DataFrame,  # pylint: disable = redefined-outer-name
    date_dataset: DataFrame,  # pylint: disable = redefined-outer-name
    str_dataset: DataFrame,  # pylint: disable = redefined-outer-name
) -> dict[str, DataFrame]:
    return {"int": int_dataset, "date": date_dataset, "str": str_dataset}


@pytest.fixture
def datasets(request: pytest.FixtureRequest, datasets_lookup: dict[str, DataFrame]) -> DataFrame:  # pylint: disable = redefined-outer-name
    return datasets_lookup.get(request.param)


@pytest.fixture(params=[SequenceModel, GbrModel])
def model_sample(request: pytest.FixtureRequest) -> Model:
    options = {"epochs": 1} if isinstance(request.param, SequenceModel) else {}
    return request.param(**options)
