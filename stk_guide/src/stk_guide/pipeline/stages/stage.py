from abc import abstractmethod
from typing import ParamSpec
from attrs import define
from ..decorators import PrePostExecution
from ...entities.stocks import Stocks

StageInputs = ParamSpec("StageInputs")


class Stage:
    @abstractmethod
    @PrePostExecution.stage
    def __call__(self, context: Stocks, **kwargs: StageInputs.kwargs) -> None:
        raise NotImplementedError

    @abstractmethod
    def _init(self, **kwargs: StageInputs.kwargs) -> None:
        raise NotImplementedError
