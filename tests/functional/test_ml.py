from datetime import datetime
from typing import Literal, Type
from attr import dataclass
from pandas import DataFrame, Series, concat
import pytest
from stk_guide.ml.encoding.algorithms import DatetimeCoder, IdentityCoder, MinMaxCoder, OneHotCoder, OrdinalCoder
from stk_guide.ml.encoding.encoder import Encoder
from stk_guide.ml.models.model import Model
from stk_guide.ml.scoring.scorer import RatingsScorer


def test_models(model_sample: Model, mix_dataset: DataFrame) -> None:
    model_sample.train(mix_dataset.Features, mix_dataset.Labels.iloc[:, 0])
    test = DataFrame([["a", "b", 10, 15], ["b", "c", 20, 25]], columns=mix_dataset.Features.columns)
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
    with pytest.raises(ValueError, match="No encoder instructions for"):
        encoder(DataFrame({"nothing": [1, 2, 3, 4]}))
    with pytest.raises(UnboundLocalError, match="Encoder.fit must be called before"):
        Encoder()(datasets.Features)


def test_cst_feature_encoding(mix_dataset: DataFrame) -> None:
    encoder = Encoder(feature_encoders={"x1": OrdinalCoder()})
    encoder.fit(mix_dataset.Features)
    edata = encoder(mix_dataset.Features)
    assert isinstance(edata, DataFrame)
    assert len(edata) == len(mix_dataset)


def test_cst_scaler_encoding(mix_dataset: DataFrame) -> None:
    encoder = Encoder(feature_scalers={"x1": MinMaxCoder()})
    encoder.fit(mix_dataset)
    edata = encoder(mix_dataset)
    assert isinstance(edata, DataFrame)
    assert len(edata) == len(mix_dataset)


def test_scorer(ratings: DataFrame) -> None:
    scr = RatingsScorer()
    test = scr(ratings)
    assert isinstance(test, Series)
    assert len(test) == 2
