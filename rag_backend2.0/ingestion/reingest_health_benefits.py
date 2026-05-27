"""
One-shot ingestion of quit-smoking health benefit milestones into Qdrant.

Uses static curated content (CDC / NHS / ACS / AHA facts) instead of live
URL scraping — more reliable and faster. Run once to seed the collection.

Usage:
    python -m ingestion.reingest_health_benefits
"""
from __future__ import annotations

import asyncio
import sys
from pathlib import Path

# Allow running as a module from the repo root
sys.path.insert(0, str(Path(__file__).parent.parent))

from app.config import settings
from app.observability.logging import configure_logging, get_logger
from app.retrieval.vector_store import get_qdrant_client
from ingestion.chunk import chunk_text

configure_logging()
logger = get_logger(__name__)

# ── Static curated content ────────────────────────────────────────────────────
# Facts sourced from CDC, NHS, ACS, AHA, and Mayo Clinic quit-smoking resources.
# Each entry maps benefit_id → (title, content text)

BENEFIT_CONTENT: dict[str, tuple[str, str]] = {
    "20min": (
        "20 Minutes After Quitting",
        """Within just 20 minutes of your last cigarette, your body begins to recover.
Your heart rate and blood pressure drop to more normal levels.
The nicotine in tobacco causes your heart rate to increase and your blood vessels to constrict.
When you stop smoking, these effects begin to reverse almost immediately.
Your heart no longer has to work as hard, reducing strain on your cardiovascular system.
This is the very first step in a lifelong journey of healing.""",
    ),
    "8hr": (
        "8 Hours After Quitting",
        """After 8 hours without a cigarette, the carbon monoxide level in your blood drops to normal.
Carbon monoxide is a toxic gas found in cigarette smoke that binds to red blood cells in place of oxygen.
When carbon monoxide levels normalise, your blood can carry significantly more oxygen.
Your cells and organs begin to receive better oxygenation, giving your body more energy.
Nicotine levels in your blood also decrease by around half, reducing cravings over time.
Many people experience withdrawal symptoms at this stage, but they are temporary and a sign your body is healing.""",
    ),
    "24hr": (
        "24 Hours After Quitting",
        """After just one day without smoking, your risk of having a heart attack begins to decrease.
Smoking dramatically increases the risk of coronary heart disease and heart attacks.
Within 24 hours, your heart attack risk starts to drop as your blood pressure stabilises.
Your lungs begin clearing out mucus and debris accumulated from smoking.
Oxygen levels in the blood continue to improve, helping every organ in your body function better.
Your sense of smell and taste may begin to sharpen as nerve endings start to regenerate.""",
    ),
    "48hr": (
        "48 Hours After Quitting",
        """At 48 hours, all nicotine has been expelled from your body.
The nerve endings in your nose and mouth begin to regrow, which were damaged by cigarette smoke.
Your senses of taste and smell start improving noticeably — food tastes better and smells are more vivid.
Cravings may still be strong during this period as your brain adjusts to the absence of nicotine.
This is one of the most challenging windows for withdrawal symptoms, including irritability and headaches.
These symptoms are a positive sign — your body is actively purging toxins and resetting itself.""",
    ),
    "72hr": (
        "72 Hours (3 Days) After Quitting",
        """By 72 hours, breathing becomes noticeably easier as the bronchial tubes begin to relax.
The tiny hair-like cilia in your airways start to regrow and function better after being damaged by smoke.
Lung capacity increases as the airways are no longer inflamed by cigarette chemicals.
Your energy levels may increase as more oxygen reaches your muscles and brain.
Nicotine withdrawal peaks around this point for most people — but it does get easier from here.
Many people describe this as the hardest day, but also a major milestone in quitting.""",
    ),
    "2wk": (
        "2 Weeks After Quitting",
        """Two weeks into your quit journey, your circulation has significantly improved.
Walking and physical activity becomes easier as your lung function improves by up to 30%.
The risk of heart attack continues to drop with each passing day.
Coughing and shortness of breath begin to decrease as your airways heal.
The cilia in your airways are now recovering and more effectively clearing mucus and debris.
Many ex-smokers report feeling more energetic and clear-headed by the two-week mark.
Sleep quality often improves as your body adjusts to life without nicotine.""",
    ),
    "1mo": (
        "1 Month After Quitting",
        """After one month without smoking, your lung function continues to improve.
Many smoking-related symptoms — chronic cough, sinus congestion, fatigue, shortness of breath — begin to decrease.
Your immune system is getting stronger, making it easier to fight off colds and infections.
Former smokers report better skin appearance as circulation improves and skin receives more oxygen.
The financial savings from not buying cigarettes become significant over a month.
Psychologically, many people feel a sense of accomplishment and increased confidence in their ability to quit.""",
    ),
    "3mo": (
        "3 Months After Quitting",
        """At three months, your circulation has substantially improved.
Lung function has increased by up to 30% compared to when you were smoking.
For those who were pregnant or planning to conceive, fertility improves significantly.
The risk of premature birth decreases for female former smokers who quit early in pregnancy.
Sperm count and motility improves in male former smokers.
Mucus production in the lungs has decreased, reducing coughing and congestion significantly.
Your body's ability to fight infections continues to strengthen.""",
    ),
    "6mo": (
        "6 Months After Quitting",
        """Six months after quitting, coughing, wheezing, and breathing problems continue to improve.
Your lungs are significantly cleaner — the cilia are fully functional and effectively clearing debris.
Stress levels often decrease as the cycle of nicotine craving and relief no longer controls your day.
Many people report that smoking-related anxiety and irritability has greatly reduced or disappeared.
Your risk of various cancers is beginning to drop compared to someone who is still smoking.
The psychological habit of smoking is becoming weaker as new, healthy routines are established.""",
    ),
    "1yr": (
        "1 Year After Quitting",
        """After one full year of not smoking, your risk of coronary heart disease has halved.
Your excess risk of heart disease is now 50% less than that of a current smoker.
This is one of the most significant health milestones in the quitting journey.
Your lungs are dramatically cleaner and healthier than they were a year ago.
Your risk of stroke has decreased and continues to decline toward that of a non-smoker.
Many ex-smokers at this stage report feeling the best they have in years.
Celebrate this enormous achievement — one year is a major milestone.""",
    ),
    "5yr": (
        "5 Years After Quitting",
        """Five years after quitting, your stroke risk is now the same as a non-smoker's.
The arteries and blood vessels that were damaged by smoking have substantially recovered.
Your risk of cancers of the mouth, throat, oesophagus, and bladder has halved compared to when you smoked.
Cervical cancer risk drops to the same level as a non-smoker for female former smokers.
Your heart disease risk continues to fall toward that of someone who has never smoked.
The long-term investment in quitting is paying off dramatically in reduced cancer and cardiovascular risk.""",
    ),
    "10yr": (
        "10 Years After Quitting",
        """Ten years after quitting, your risk of dying from lung cancer is approximately half that of a continuing smoker.
Your risk of cancer of the larynx (voice box) and pancreas has decreased significantly.
Pre-cancerous cells in your lungs have been replaced with healthy cells.
Your risk of cancers of the kidney, oesophagus, and bladder continues to decrease.
Your overall cancer risk profile is dramatically lower than it would have been had you continued smoking.""",
    ),
    "15yr": (
        "15 Years After Quitting",
        """Fifteen years after quitting smoking, your risk of coronary heart disease is now the same as a non-smoker.
Your heart attack risk has returned to normal — equivalent to someone who has never smoked.
The risk of pancreatic cancer has also fallen to the same level as a non-smoker.
Your overall cardiovascular system has recovered to a healthy baseline.
Many former smokers at this stage show no statistically significant difference in heart disease risk from lifelong non-smokers.""",
    ),
    "20yr": (
        "20 Years After Quitting",
        """Twenty years after quitting, your risk of cancers of the mouth, throat, oesophagus, and bladder is the same as a non-smoker.
Your risk of pancreatic cancer has returned to the same level as someone who has never smoked.
Your overall cancer and cardiovascular risk profile is now equivalent to a lifelong non-smoker in almost all respects.
Two decades of healing have undone the vast majority of the damage caused by tobacco use.
Studies show that people who quit smoking before age 40 reduce the risk of dying from smoking-related disease by about 90%.
Your decision to quit was one of the most impactful health choices you will ever make.""",
    ),
}


async def embed_texts(texts: list[str]) -> list[list[float]]:
    """Embed a list of texts using Cloudflare Workers AI."""
    import httpx
    url = (
        f"https://api.cloudflare.com/client/v4/accounts/"
        f"{settings.cf_account_id}/ai/run/{settings.cf_embedding_model}"
    )
    headers = {"Authorization": f"Bearer {settings.cf_workers_ai_token}"}
    async with httpx.AsyncClient(timeout=30) as client:
        resp = await client.post(url, headers=headers, json={"text": texts})
        resp.raise_for_status()
        data = resp.json()
        return data["result"]["data"]


async def main() -> None:
    from qdrant_client.models import Distance, PointStruct, VectorParams
    import uuid

    client = get_qdrant_client()
    collection = settings.qdrant_health_benefits_collection

    # Ensure collection exists
    try:
        await client.get_collection(collection)
        logger.info("collection_exists", collection=collection)
    except Exception:
        await client.create_collection(
            collection_name=collection,
            vectors_config=VectorParams(size=384, distance=Distance.COSINE),
        )
        logger.info("collection_created", collection=collection)

    total_chunks = 0
    errors: list[str] = []

    for benefit_id, (title, content) in BENEFIT_CONTENT.items():
        source_id = f"health_benefit_{benefit_id}"
        logger.info("ingesting_benefit", benefit_id=benefit_id)

        try:
            chunks = chunk_text(
                content,
                source_id=source_id,
                source_type="government",
                benefit_id=benefit_id,
                topic_tags=["health_benefit", "quit_smoking"],
            )
            texts = [c.content for c in chunks]

            # Embed in one batch
            vectors = await embed_texts(texts)

            points = []
            for chunk, vector in zip(chunks, vectors):
                points.append(PointStruct(
                    id=chunk.id,  # stable deterministic UUID
                    vector=vector,
                    payload={
                        "text": chunk.content,
                        "source_id": source_id,
                        "benefit_id": benefit_id,
                        "title": title,
                        "source_type": "health_benefit",
                        "chunk_index": chunk.chunk_index,
                        "topic_tags": chunk.topic_tags,
                    },
                ))

            await client.upsert(collection_name=collection, points=points)
            total_chunks += len(points)
            print(f"  ✓ {benefit_id}: {len(points)} chunk(s)")

        except Exception as exc:
            msg = f"FAILED benefit={benefit_id}: {exc}"
            errors.append(msg)
            print(f"  ✗ {msg}")

    print(f"\n{'='*60}")
    print(f"Total chunks ingested: {total_chunks}")
    if errors:
        print(f"Errors ({len(errors)}):")
        for e in errors:
            print(f"  • {e}")
    else:
        print("All 14 health benefits ingested successfully ✅")


if __name__ == "__main__":
    asyncio.run(main())
