"""Groq structured-output and streaming compatibility tests."""
from types import SimpleNamespace
from unittest.mock import AsyncMock, MagicMock

import httpx
import pytest
from groq import BadRequestError

from app.llm.groq_client import GroqClient, _structured_output_error_code


def _completion(content: str = "{}"):
    return SimpleNamespace(
        usage=None,
        choices=[SimpleNamespace(message=SimpleNamespace(content=content))],
    )


@pytest.mark.parametrize(
    ("body", "expected"),
    [
        ({"code": "json_validate_failed"}, "json_validate_failed"),
        ({"error": {"code": "json_validate_failed"}}, "json_validate_failed"),
    ],
)
def test_structured_output_error_code_supports_sdk_body_shapes(body, expected):
    request = httpx.Request("POST", "https://api.groq.com/openai/v1/chat/completions")
    error = BadRequestError("bad", response=httpx.Response(400, request=request), body=body)
    assert _structured_output_error_code(error) == expected


@pytest.mark.asyncio
async def test_complete_uses_strict_json_schema():
    client = GroqClient(model="openai/gpt-oss-20b")
    client._client = MagicMock()
    client._client.chat.completions.create = AsyncMock(return_value=_completion())
    schema = {
        "type": "object",
        "properties": {"value": {"type": "string"}},
        "required": ["value"],
        "additionalProperties": False,
    }

    await client.complete([], response_schema=schema)

    kwargs = client._client.chat.completions.create.await_args.kwargs
    assert kwargs["response_format"] == {
        "type": "json_schema",
        "json_schema": {"name": "hailey_response", "strict": True, "schema": schema},
    }


@pytest.mark.asyncio
async def test_complete_retries_without_response_format_after_json_validation_error():
    client = GroqClient(model="openai/gpt-oss-20b")
    client._client = MagicMock()
    request = httpx.Request("POST", "https://api.groq.com/openai/v1/chat/completions")
    response = httpx.Response(400, request=request)
    error = BadRequestError(
        "JSON validation failed",
        response=response,
        body={"code": "json_validate_failed"},
    )
    create = AsyncMock(side_effect=[error, _completion('{"value":"ok"}')])
    client._client.chat.completions.create = create

    result = await client.complete([], response_schema={"type": "object"})

    assert result == '{"value":"ok"}'
    assert create.await_count == 2
    assert "response_format" in create.await_args_list[0].kwargs
    assert "response_format" not in create.await_args_list[1].kwargs


@pytest.mark.asyncio
async def test_stream_passes_usage_option_through_extra_body():
    client = GroqClient(model="openai/gpt-oss-120b")
    client._client = MagicMock()

    async def chunks():
        yield SimpleNamespace(
            usage=None,
            choices=[SimpleNamespace(delta=SimpleNamespace(content="hello"))],
        )

    client._client.chat.completions.create = AsyncMock(return_value=chunks())
    output = [token async for token in client.stream([])]

    assert output == ["hello"]
    kwargs = client._client.chat.completions.create.await_args.kwargs
    assert "stream_options" not in kwargs
    assert kwargs["extra_body"] == {"stream_options": {"include_usage": True}}
