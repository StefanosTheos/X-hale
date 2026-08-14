"""Safety post-processing must withhold prohibited medical output."""
from app.safety.content_filter import filter_response


def test_prescription_language_is_replaced_not_disclaimed():
    unsafe = "You should take 40 mg of this medicine every morning."
    content, blocked, reason = filter_response(unsafe)

    assert blocked is True
    assert reason == "prescription_language_detected"
    assert unsafe not in content
    assert "doctor or pharmacist" in content


def test_diagnosis_language_is_replaced():
    unsafe = "You are suffering from a medical condition."
    content, blocked, reason = filter_response(unsafe)

    assert blocked is True
    assert reason == "diagnosis_language_detected"
    assert unsafe not in content


def test_general_health_information_passes_unchanged():
    safe = "Nicotine replacement therapy can reduce cravings; ask a pharmacist what suits you."
    assert filter_response(safe) == (safe, False, "")


def test_coping_instruction_is_not_mistaken_for_prescription():
    safe = "Take a slow, deep breath and let the craving pass."
    assert filter_response(safe) == (safe, False, "")
