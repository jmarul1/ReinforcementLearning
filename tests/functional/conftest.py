from datetime import datetime, timedelta, date
from pandas import DataFrame, MultiIndex, concat
import pytest
from stk_guide.entities.options import Options
from stk_guide.entities.stock import Stock
from stk_guide.ml.encoding.encoder import Encoder
from stk_guide.ml.models.gbr import GbrModel
from stk_guide.ml.models.model import Model
from stk_guide.ml.models.sequence import SequenceModel
from stk_guide.pipeline.context import Context
from stk_guide.pipeline.stages.collecting import PriceCollector
from stk_guide.pipeline.stages.training import ClosePriceTrainer


@pytest.fixture
def stock_sample() -> Stock:
    return Stock("AAPL", "Apple")


@pytest.fixture
def context_sample1(stock_sample: Stock) -> Context:  # pylint: disable = redefined-outer-name
    return Context(stock_sample)


@pytest.fixture
def options_sample(stock_sample: Stock) -> Options:  # pylint: disable = redefined-outer-name
    stock_sample.populate_options(max_number=1)
    return stock_sample.options


@pytest.fixture
def context_sample2(context_sample1: Context) -> Context:  # pylint: disable = redefined-outer-name
    PriceCollector()(context_sample1, years_back=0.05)
    return context_sample1


@pytest.fixture
def context_sample3(context_sample2: Context) -> Context:  # pylint: disable = redefined-outer-name
    context_sample2.preprocessor = Encoder().fit(context_sample2.stock.prices.features())
    return context_sample2


@pytest.fixture
def context_sample4(context_sample3: Context) -> Context:  # pylint: disable = redefined-outer-name
    ClosePriceTrainer(GbrModel())(context_sample3)
    return context_sample3


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
def mix_dataset(str_dataset: DataFrame, int_dataset: DataFrame) -> DataFrame:  # pylint: disable = redefined-outer-name
    data = concat([str_dataset.Features, int_dataset.Features, int_dataset.Labels], axis=1)
    data.columns = MultiIndex.from_arrays([["Features", "Features", "Features", "Features", "Labels"], ["x1", "x2", "x3", "x4", "o1"]])
    return data


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


@pytest.fixture
def encoder(mix_dataset: DataFrame) -> Encoder:  # pylint: disable = redefined-outer-name
    _encoder = Encoder()
    _encoder.fit(mix_dataset.Features)
    return _encoder


@pytest.fixture(params=[SequenceModel, GbrModel])
def model_sample(request: pytest.FixtureRequest, encoder: Encoder) -> Model:  # pylint: disable = redefined-outer-name
    options = {"epochs": 1} if isinstance(request.param, SequenceModel) else {}
    options["preprocessor"] = encoder
    return request.param(**options)


@pytest.fixture
def ratings() -> DataFrame:
    return DataFrame([[date.today(), 32, 15, 5], [date.today(), 30, 10, 10]], columns=["date", "buy", "hold", "sell"], index=["AAPL", "NVDA"])
