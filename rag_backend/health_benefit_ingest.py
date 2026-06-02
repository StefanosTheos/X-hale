from ingest import ingest_benefit_sources

benefit_sources = {
    "benefit_20min": [
        "https://www.cancer.org/cancer/risk-prevention/tobacco/guide-quitting-smoking/benefits-of-quitting-smoking-over-time.html",
        "https://www.cdc.gov/tobacco/about/benefits-of-quitting.html"
    ],
    "benefit_12hours": [
        "https://www.nhs.uk/better-health/quit-smoking/why-quit-smoking/benefits-of-quitting-smoking/#article",
        "https://www.mayoclinic.org/healthy-lifestyle/quit-smoking/in-depth/smoking/art-20045452"
    ],
    "benefit_24hours": [
        "https://www.cdc.gov/tobacco/about/benefits-of-quitting.html"
    ],
    "benefit_48hours": [
        "https://www.who.int/news-room/questions-and-answers/item/tobacco-health-benefits-of-smoking-cessation"
    ],
    "benefit_2weeks": [
        "https://www.cdc.gov/tobacco/about/benefits-of-quitting.html",
        "https://www.mayoclinic.org/healthy-lifestyle/quit-smoking/in-depth/smoking/art-20045452"
    ],
    "benefit_1month": [
        "https://www.nhs.uk/better-health/quit-smoking/why-quit-smoking/benefits-of-quitting-smoking/#article"
    ],
    "benefit_1to9months": [
        "https://www.cdc.gov/tobacco/about/benefits-of-quitting.html"
    ],
    "benefit_1year": [
        "https://www.cancer.org/cancer/risk-prevention/tobacco/guide-quitting-smoking/benefits-of-quitting-smoking-over-time.html"
    ],
    "benefit_1to2years": [
        "https://www.mayoclinic.org/healthy-lifestyle/quit-smoking/in-depth/smoking/art-20045452",
        "https://www.hopkinsmedicine.org/health/wellness-and-prevention/the-benefits-of-quitting-smoking"
    ],
    "benefit_3to6years": [
        "https://www.who.int/news-room/questions-and-answers/item/tobacco-health-benefits-of-smoking-cessation"
    ],
    "benefit_5to10years": [
        "https://www.cdc.gov/tobacco/about/benefits-of-quitting.html",
        "https://www.nhs.uk/better-health/quit-smoking/why-quit-smoking/benefits-of-quitting-smoking/#article"
    ],
    "benefit_10years": [
        "https://www.cancer.org/cancer/risk-prevention/tobacco/guide-quitting-smoking/benefits-of-quitting-smoking-over-time.html"
    ],
    "benefit_15years": [
        "https://www.mayoclinic.org/healthy-lifestyle/quit-smoking/in-depth/smoking/art-20045452",
        "https://www.hopkinsmedicine.org/health/wellness-and-prevention/the-benefits-of-quitting-smoking"
    ],
    "benefit_20years": [
        "https://www.who.int/news-room/questions-and-answers/item/tobacco-health-benefits-of-smoking-cessation",
        "https://www.health.harvard.edu/newsletter_article/why-quit-smoking"
    ]
}


if __name__ == "__main__":
    for benefit_id, urls in benefit_sources.items():
        print(f"Ingesting sources for {benefit_id}...")
        ingest_benefit_sources(benefit_id, urls)

    print("All health benefits ingested successfully!")