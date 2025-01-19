from __future__ import annotations
from typing import Callable, TYPE_CHECKING
from functools import wraps
from attrs import define
from ..entities.stocks import Stocks

if TYPE_CHECKING:
    from .stages.stage import Stage, StageInputs


@define
class PrePostExecution:
    @staticmethod
    def stage(func: Callable) -> Callable:
        @wraps(func)
        def func_wrapper(stage: Stage, context: Stocks, **kwargs: StageInputs.kwargs) -> None:
            stage._init(**kwargs)  # pylint: disable=protected-access
            func(stage, context, **kwargs)

        return func_wrapper
