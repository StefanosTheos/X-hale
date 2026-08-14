"""Request-scoped LLM token accounting for benchmark observability."""
from __future__ import annotations

from contextvars import ContextVar, Token
from dataclasses import dataclass, field


@dataclass
class LLMUsage:
    prompt_tokens: int = 0
    completion_tokens: int = 0
    requests: int = 0
    by_model: dict[str, dict[str, int]] = field(default_factory=dict)

    def add(self, model: str, prompt_tokens: int, completion_tokens: int) -> None:
        self.prompt_tokens += prompt_tokens
        self.completion_tokens += completion_tokens
        self.requests += 1
        model_usage = self.by_model.setdefault(
            model, {"prompt_tokens": 0, "completion_tokens": 0, "requests": 0}
        )
        model_usage["prompt_tokens"] += prompt_tokens
        model_usage["completion_tokens"] += completion_tokens
        model_usage["requests"] += 1

    def as_dict(self) -> dict:
        return {
            "prompt_tokens": self.prompt_tokens,
            "completion_tokens": self.completion_tokens,
            "total_tokens": self.prompt_tokens + self.completion_tokens,
            "requests": self.requests,
            "by_model": self.by_model,
        }


_current_usage: ContextVar[LLMUsage | None] = ContextVar("llm_usage", default=None)


def begin_usage_tracking() -> tuple[LLMUsage, Token]:
    usage = LLMUsage()
    return usage, _current_usage.set(usage)


def end_usage_tracking(token: Token) -> None:
    _current_usage.reset(token)


def record_usage(model: str, usage: object | None) -> None:
    accumulator = _current_usage.get()
    if accumulator is None or usage is None:
        return
    prompt = int(getattr(usage, "prompt_tokens", 0) or 0)
    completion = int(getattr(usage, "completion_tokens", 0) or 0)
    accumulator.add(model, prompt, completion)
