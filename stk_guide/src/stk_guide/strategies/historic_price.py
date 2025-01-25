from datetime import datetime, timedelta
from attrs import define, field
from pandas import DataFrame, concat
from .strategy import Strategy
from ..entities.prices import PricesEnum
from ..entities.prediction import Prediction
from ..entities.stock import Stock
from ..pipeline.pipeline import Pipeline
from ..pipeline.pipeline_stages import PipelineStages
from ..ml.encoding.encoder import Encoder
from ..ml.encoding.algorithms import MinMaxCoder
from ..pipeline.stages.collecting import PriceCollector


@define
class HistoricPrice(Strategy):
    pipeline_stages: PipelineStages
    pipeline: Pipeline = field(init=False)

    def __call__(self, stock: Stock, years_back: int, days_fwd: int) -> Prediction:
        stock.populate_prices(years_back=years_back)
        history = stock.prices.features()
        projection = DataFrame({PricesEnum.DATETIME.value: [datetime.now().astimezone() + timedelta(days=iday) for iday in range(days_fwd)]})
        self.pipeline = Pipeline()
        self.pipeline.context.stock = stock
        self.pipeline.context.preprocessor = self.setup_preprocessor(history, projection)
        self.pipeline.add(PriceCollector(), years_back=years_back)
        self.pipeline.add(self.pipeline_stages.trainer)
        self.pipeline.add(self.pipeline_stages.predictor, future_space=projection)
        self.pipeline.execute()
        return self.pipeline.context

    def setup_preprocessor(self, history: DataFrame, projection: DataFrame) -> None:
        preprocessor = Encoder(feature_scalers={PricesEnum.DATETIME.value: MinMaxCoder()})
        data = concat([history, projection])
        return preprocessor.fit(data)
