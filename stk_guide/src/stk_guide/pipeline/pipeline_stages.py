from attrs import define, field
from ..pipeline.stages.preprocessing import Preprocessor
from ..pipeline.stages.collecting import Collector
from ..pipeline.stages.predicting import Predictor
from ..pipeline.stages.training import Trainer


@define
class PipelineStages:
    collector: Collector = field(default=None, kw_only=True)
    preprocessor: Preprocessor = field(default=None, kw_only=True)
    trainer: Trainer = field(default=None, kw_only=True)
    predictor: Predictor = field(default=None, kw_only=True)
