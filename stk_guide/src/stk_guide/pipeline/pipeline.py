from typing import Self
from attrs import field, define
from ..logger import Logger, LoggerObject
from ..entities.stocks import Stocks
from .context import Context
from .stages.stage import Stage, StageInputs


@define
class Pipeline(list):
    context: Context = field(factory=Context)
    _current_idx: int = field(init=False, default=0)
    _logger: LoggerObject = field(init=False)

    def __attrs_post_init__(self) -> None:
        self._logger = Logger()(__name__)

    def execute(self) -> None:
        for self._current_idx, (stage, kwargs) in enumerate(self, start=1):
            self._logger.debug(f"Running {stage} {self._current_idx}/{len(self)}")
            stage(context=self.context, **kwargs)

    def add(self, stage: Stage, **kwargs: StageInputs.kwargs) -> None:
        self.append(tuple([stage, kwargs]))

    def append(self, stage_pkg: tuple[Stage, dict]) -> None:
        self._validate(stage_pkg)
        super().append(stage_pkg)

    def _validate(self, stage_pkg: tuple[Stage, dict]) -> None:
        if len(stage_pkg) != 2 or not isinstance(stage_pkg[0], Stage) or not isinstance(stage_pkg[1], dict):
            raise ValueError(f"Arguments passed are of the wrong type: {stage_pkg}")

    def insert(self, index: int, stage: Stage) -> None:
        self._validate(stage)
        super().insert(index, stage)

    def __setitem__(self, index: int, stage: Stage) -> None:
        self._validate(stage)
        super().__setitem__(index, stage)

    def __iadd__(self, stage: Stage) -> Self:
        self._validate(stage)
        self.append(stage)
        return self

    def __add__(self, iterable: Self) -> Self:
        new_pipeline = Pipeline(self)
        for stage in iterable:
            new_pipeline += stage
        return new_pipeline

    def _show_flow(self) -> str:
        def create_line(stages: list[str], n1: int, n2: int, reverse: bool) -> str:
            beg, end = ("|- ", "") if reverse else ("", " -|")
            lst, joiner = (stages[n1:n2][::-1], " <- ") if reverse else (stages[n1:n2], " -> ")
            return beg + joiner.join(f"{stage}" for stage in lst) + end

        stages = [f"{stage}" for stage in self]
        stages[self._current_idx - 1] = f"\033[92m{stages[self._current_idx-1]}\033[00m"
        npl = 8
        count1, count2 = int(len(self) / npl), len(self) % npl
        lines = []
        for idx in range(count1):
            lines.append(create_line(stages, npl * idx, npl * (idx + 1), idx % 2 != 0))
        if count2 > 0:
            lines.append(create_line(stages, npl * (idx + 1), len(self), (idx + 1) % 2 != 0))
        print("\n".join(lines))
