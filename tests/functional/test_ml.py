from datetime import datetime
from typing import Literal, Type
from attr import dataclass
from pandas import DataFrame, Series, concat
import pytest
from stk_guide.ml.encoding.algorithms import DatetimeCoder, IdentityCoder, MinMaxCoder, OneHotCoder, OrdinalCoder
from stk_guide.ml.encoding.encoder import Encoder
from stk_guide.ml.models.model import Model
from stk_guide.ml.models.sequence import SequenceModel


def test_models(model_sample: Model, int_dataset: DataFrame, str_dataset: DataFrame) -> None:
    features = concat([int_dataset.Features, str_dataset.Features], axis=1)
    features.columns = ["x1", "x2", "x3", "x4"]
    model_sample.train(features, int_dataset.Labels)
    test = DataFrame([[10, 15, "a", "b"], [25, 25, "b", "c"]], columns=features.columns)
    preds = model_sample.predict(test)
    assert isinstance(preds, Series)
    assert len(preds) == 2
    with pytest.raises(ValueError, match="Predicting features shape/types must match that of training"):
        model_sample.predict(DataFrame([[10, 15, 1, 1]]))


@pytest.mark.parametrize("coder", [MinMaxCoder, IdentityCoder, OrdinalCoder, OneHotCoder, DatetimeCoder])
def test_encoders_scalar(
    coder: type[MinMaxCoder | IdentityCoder | OrdinalCoder | OneHotCoder | DatetimeCoder], datasets_lookup: dict[str, DataFrame]
) -> None:
    _coder = coder()
    if isinstance(_coder, (MinMaxCoder, IdentityCoder)):
        dataset = datasets_lookup["int"]
    elif isinstance(_coder, (OrdinalCoder, OneHotCoder)):
        dataset = datasets_lookup["str"]
    else:
        dataset = datasets_lookup["date"]
    data = dataset.Features.i1.to_list()
    _coder.fit(data)
    edata = _coder.code(data)
    assert isinstance(edata, list)
    assert len(edata) == len(dataset)
    if isinstance(coder, OneHotCoder):
        assert isinstance(edata[0], list)


@pytest.mark.parametrize("datasets", ["int", "date", "str"], indirect=True)
def test_encoding(datasets: DataFrame) -> None:
    encoder = Encoder()
    encoder.fit(datasets.Features)
    edata = encoder(datasets.Features)
    assert isinstance(edata, DataFrame)
    assert len(edata) == len(datasets)
    with pytest.raises(ValueError, match="No coder found for"):
        encoder(DataFrame({"nothing": [1, 2, 3, 4]}))


def test_custom_encoding(str_dataset: DataFrame) -> None:
    encoder = Encoder(custom_encoding={"i1": OrdinalCoder()})
    encoder.fit(str_dataset.Features)
    edata = encoder(str_dataset.Features)
    assert isinstance(edata, DataFrame)
    assert len(edata) == len(str_dataset)


def test_mix_encoding(str_dataset: DataFrame, int_dataset: DataFrame) -> None:
    encoder = Encoder(custom_encoding={"x1": OrdinalCoder()})
    data = concat([str_dataset.Features, int_dataset.Features], axis=1)
    data.columns = ["x1", "x2", "x3", "x4"]
    encoder.fit(data)
    edata = encoder(data)
    assert isinstance(edata, DataFrame)
    assert len(edata) == len(data)
