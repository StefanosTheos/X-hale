"""Strict JSON schemas used by Groq structured-output calls."""
from __future__ import annotations


TRIAGE_SCHEMA: dict = {
    "type": "object",
    "properties": {
        "intent": {"type": "string", "enum": [
            "medical_question", "craving_support", "emotional_support",
            "reflection", "relapse_concern", "off_topic",
            "needs_clarification", "general_conversation",
        ]},
        "emotion": {"type": "string", "enum": [
            "sadness", "fear", "anxiety", "shame", "guilt", "frustration",
            "loneliness", "anger", "joy", "neutral", "confusion", "hope", "calm",
        ]},
        "topic_relevance": {"type": "string", "enum": ["relevant", "irrelevant"]},
        "urgency": {"type": "string", "enum": ["low", "medium", "high"]},
        "crisis_flag": {"type": "boolean"},
        "requested_specialists": {
            "type": "array",
            "items": {"type": "string", "enum": [
                "medical", "craving_support", "emotional_support", "reflection", "relapse_risk",
            ]},
        },
    },
    "required": [
        "intent", "emotion", "topic_relevance", "urgency",
        "crisis_flag", "requested_specialists",
    ],
    "additionalProperties": False,
}


_KEY_POINT_SCHEMA = {
    "type": "object",
    "properties": {
        "claim": {"type": "string"},
        "source_id": {"type": "string"},
    },
    "required": ["claim", "source_id"],
    "additionalProperties": False,
}

_APP_ACTION_SCHEMA = {
    "type": "object",
    "properties": {
        "label": {"type": "string"},
        "deeplink": {"type": "string"},
        "description": {"type": "string"},
    },
    "required": ["label", "deeplink", "description"],
    "additionalProperties": False,
}

SPECIALIST_DRAFT_SCHEMA: dict = {
    "type": "object",
    "properties": {
        "agent": {"type": "string"},
        "key_points": {"type": "array", "items": _KEY_POINT_SCHEMA},
        "tone_hint": {"type": "string"},
        "suggested_deeplinks": {"type": "array", "items": _APP_ACTION_SCHEMA},
        "raw_context": {"type": "string"},
    },
    "required": ["agent", "key_points", "tone_hint", "suggested_deeplinks", "raw_context"],
    "additionalProperties": False,
}


MEMORY_FACTS_SCHEMA: dict = {
    "type": "array",
    "items": {
        "type": "object",
        "properties": {
            "fact_type": {"type": "string", "enum": [
                "trigger", "coping_strategy_validated", "coping_strategy_failed",
                "nrt_use", "social_context", "motivation", "stage_of_change",
                "past_attempt_history", "physical_symptom_reported",
            ]},
            "fact_key": {"type": "string"},
            "fact_value": {"type": "string"},
            "confidence": {"type": "number", "minimum": 0.0, "maximum": 1.0},
        },
        "required": ["fact_type", "fact_key", "fact_value", "confidence"],
        "additionalProperties": False,
    },
}
