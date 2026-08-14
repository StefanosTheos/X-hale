from types import SimpleNamespace

from app.llm.usage import begin_usage_tracking, end_usage_tracking, record_usage


def test_request_scoped_usage_tracks_models_separately():
    usage, token = begin_usage_tracking()
    try:
        record_usage("small", SimpleNamespace(prompt_tokens=100, completion_tokens=20))
        record_usage("large", SimpleNamespace(prompt_tokens=80, completion_tokens=40))
        record_usage("small", SimpleNamespace(prompt_tokens=50, completion_tokens=10))
    finally:
        end_usage_tracking(token)

    assert usage.as_dict() == {
        "prompt_tokens": 230,
        "completion_tokens": 70,
        "total_tokens": 300,
        "requests": 3,
        "by_model": {
            "small": {"prompt_tokens": 150, "completion_tokens": 30, "requests": 2},
            "large": {"prompt_tokens": 80, "completion_tokens": 40, "requests": 1},
        },
    }
