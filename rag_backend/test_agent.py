import requests
from deepeval import evaluate
from deepeval.test_case import LLMTestCase
from deepeval.metrics import (
    AnswerRelevancyMetric,
    FaithfulnessMetric,
    HallucinationMetric,
    ContextualRelevancyMetric
    )

# -----------------------------
# CONFIG
# -----------------------------
BASE_URL = "http://localhost:8080"
CHAT_ENDPOINT = f"{BASE_URL}/chat/"
DELETE_HISTORY_ENDPOINT = f"{BASE_URL}/history/{{user_id}}"

TEST_USER_ID = "deepeval_test_user"

# -----------------------------
# Helpers
# -----------------------------
def reset_user_history():
    requests.delete(DELETE_HISTORY_ENDPOINT.format(user_id=TEST_USER_ID))

def call_agent(message: str):
    res = requests.post(CHAT_ENDPOINT, json={
        "user_id": TEST_USER_ID,
        "input": message
    }, timeout=60)
    res.raise_for_status()
    return res.json()

# -----------------------------
# TEST CASES
# -----------------------------
test_inputs = [
    "What happens to your lungs after quitting smoking?",
    #"Is nicotine gum safer than cigarettes?",
    #"I'm feeling really anxious and craving a cigarette right now."
]

test_cases = []

reset_user_history()

for user_input in test_inputs:
    result = call_agent(user_input)
    actual_output = result["response"]

    refined_context = result.get("refined_context", "")

    test_cases.append(
        LLMTestCase(
            input=user_input,
            actual_output=actual_output,
            retrieval_context=[refined_context]
        )
    )



# -----------------------------
# METRICS
# -----------------------------
metrics = [
    #AnswerRelevancyMetric(threshold=0.6, async_mode=False),
    #FaithfulnessMetric(threshold=0.6, async_mode=False),
    #HallucinationMetric(threshold=0.6, async_mode=False),
    ContextualRelevancyMetric(threshold=0.6, async_mode=False),

]

# -----------------------------
# RUN
# -----------------------------
evaluate(test_cases=test_cases, metrics=metrics)
