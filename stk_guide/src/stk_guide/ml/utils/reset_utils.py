from copy import deepcopy
from enum import Enum
from inspect import signature
from typing import Any, Self


class ResetDefaults(Enum):
    CLONE_RESET_FN = "clone_reset"


class ResetClone:
    def clone_reset(self, inst: Any, dont_resets: list[str] = None) -> Self:
        args, kwargs = [], {}
        sig = signature(inst.__class__)
        for arg_name, arg_value in sig.parameters.items():
            current_arg_val = getattr(inst, arg_name)
            reset_arg_val = self.clone_reset_any(current_arg_val)
            match arg_value.kind:
                case arg_value.POSITIONAL_ONLY:
                    args.append(reset_arg_val)
                case arg_value.POSITIONAL_OR_KEYWORD | arg_value.KEYWORD_ONLY:
                    kwargs[arg_name] = reset_arg_val
                case _:
                    raise ValueError(inst)
        return inst.__class__(*args, **kwargs)

    def clone_reset_any(self, value: Any) -> Any:
        if hasattr(value, ResetDefaults.CLONE_RESET_FN.value):
            new = value.clone_reset()
        elif isinstance(value, dict):
            new = self.clone_reset_dict(value)
        elif isinstance(value, list):
            new = self.clone_reset_list(value)
        else:
            new = deepcopy(value)
        return new

    def clone_reset_dict(self, dt: dict[Any, Any]) -> dict[Any, Any]:
        new = {}
        for current_key, current_value in dt.items():
            reset_key = current_key.clone_reset() if hasattr(current_key, ResetDefaults.CLONE_RESET_FN.value) else deepcopy(current_key)
            reset_value = current_value.clone_reset() if hasattr(current_value, ResetDefaults.CLONE_RESET_FN.value) else deepcopy(current_value)
            new[reset_key] = reset_value
        return new

    def clone_reset_list(self, lst: list[Any]) -> list[Any]:
        return [
            (current_value.clone_reset() if hasattr(current_value, ResetDefaults.CLONE_RESET_FN.value) else deepcopy(current_value))
            for current_value in lst
        ]
