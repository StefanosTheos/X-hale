"""Boundary-safe retrieval and ingestion excerpt regressions."""
from app.models.retrieval import bounded_excerpt
from ingestion.chunk import chunk_text


def test_bounded_excerpt_does_not_cut_a_medical_sentence():
    text = (
        "Introductory material that is not important. " * 8
        + "After 3 to 9 months, coughs, wheezing, and breathing problems improve. "
        + "A final sentence follows."
    )
    excerpt = bounded_excerpt(text, 300)
    assert not excerpt.endswith("Any coughs")
    assert excerpt.endswith((".", "?", "!", "…"))


def test_chunk_overlap_starts_at_word_boundary():
    text = " ".join(f"sentence{i} has enough complete content." for i in range(40))
    chunks = chunk_text(text, "source", chunk_size=180, chunk_overlap=40)
    assert len(chunks) > 1
    assert all(not chunk.content.startswith("ntence") for chunk in chunks)
