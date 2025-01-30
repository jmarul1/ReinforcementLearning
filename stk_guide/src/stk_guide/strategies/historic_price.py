from datetime import datetime, timedelta
from dateutil.tz import gettz
from attrs import define, field
from pandas import DataFrame, concat
from .strategy import Strategy
from ..entities.prices import PricesEnum
from ..entities.prediction import Prediction
from ..entities.stock import Stock
from ..download.download_enum import TimeZone
from ..pipeline.pipeline import Pipeline
from ..pipeline.pipeline_stages import PipelineStages
from ..ml.encoding.encoder import Encoder
from ..ml.encoding.algorithms import MinMaxCoder
from ..pipeline.stages.collecting import PriceCollector


@define
class HistoricPrice(Strategy):
    pipeline_stages: PipelineStages
    pipeline: Pipeline = field(init=False)

    def __call__(self, stock: Stock, days_back: int, days_fwd: int, interval: str = None) -> Prediction:
        stock.populate_prices(days_back=days_back, interval=interval)
        history = stock.prices.features()
        tz = gettz(TimeZone.DEFAULT.value)
        projection = DataFrame({PricesEnum.DATETIME.value: [datetime.now(tz) + timedelta(hours=ihr) for ihr in range(days_fwd * 24)]})
        self.pipeline = Pipeline()
        self.pipeline.context.stock = stock
        self.pipeline.context.preprocessor = self.setup_preprocessor(history, projection)
        self.pipeline.add(PriceCollector(), days_back=days_back, interval=interval)
        self.pipeline.add(self.pipeline_stages.trainer)
        self.pipeline.add(self.pipeline_stages.predictor, future_space=projection)
        self.pipeline.execute()
        return self.pipeline.context

    def setup_preprocessor(self, history: DataFrame, projection: DataFrame) -> Encoder:
        preprocessor = Encoder(feature_scalers={PricesEnum.DATETIME.value: MinMaxCoder()})
        data = concat([history, projection])
        return preprocessor.fit(data)
