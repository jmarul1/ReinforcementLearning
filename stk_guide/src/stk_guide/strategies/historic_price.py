from datetime import datetime, timedelta
from attrs import define, field
from pandas import DataFrame
from .strategy import Strategy
from ..entities.prices import PricesEnum
from ..entities.prediction import Prediction
from ..entities.stock import Stock
from ..pipeline.pipeline import Pipeline
from ..pipeline.pipeline_stages import PipelineStages


@define
class HistoricPrice(Strategy):
    pipeline_stages: PipelineStages
    pipeline: Pipeline = field(init=False)

    def __call__(self, stock: Stock, years_back: int, days_fwd: int) -> Prediction:
        projections = DataFrame({PricesEnum.DATETIME.value: [datetime.now().astimezone() + timedelta(days=iday) for iday in range(days_fwd)]})
        self.pipeline = Pipeline()
        self.pipeline.context.stock = stock
        self.pipeline.add(self.pipeline_stages.collector, years_back=years_back)
        self.pipeline.add(self.pipeline_stages.preprocessor)
        self.pipeline.add(self.pipeline_stages.trainer)
        self.pipeline.add(self.pipeline_stages.predictor, future_space=projections)
        self.pipeline.execute()
        return self.pipeline.context.prediction
