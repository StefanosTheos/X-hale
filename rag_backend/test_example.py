from deepeval import evaluate
from deepeval.test_case import LLMTestCase
from deepeval.metrics import AnswerRelevancyMetric

test_cases = [
    LLMTestCase(
        input="What happens to your lungs after quitting smoking?",
        actual_output="Your lungs begin to heal within weeks and breathing improves."
    )
]

evaluate(test_cases=test_cases, metrics=[AnswerRelevancyMetric()])
