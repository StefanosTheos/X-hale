import os
import argparse
import logging
import tempfile
import fitz
import requests
from bs4 import BeautifulSoup
import re

from chromaClient import get_chroma_collection

logger = logging.getLogger(__name__)

MIN_LENGTH = 50 


def clean_text(text: str) -> str:
    # Collapse whitespace and strip leading/trailing characters
    text = re.sub(r'\s+', ' ', text).strip()
    return text


def ingest_txt_file(file_path: str) -> str:
    with open(file_path, "r", encoding="utf-8") as f:
        return clean_text(f.read())


def ingest_pdf_file(file_path: str) -> str:
    with fitz.open(file_path) as doc:
        text = "\n".join([page.get_text() for page in doc])
    return clean_text(text)


def ingest_url(url: str) -> str:
    response = requests.get(url)
    response.raise_for_status()
    content_type = response.headers.get("Content-Type", "").lower()

    # PDF response
    if "pdf" in content_type or url.lower().endswith(".pdf"):
        with tempfile.NamedTemporaryFile(suffix=".pdf", delete=False) as tmp:
            tmp.write(response.content)
            tmp_path = tmp.name
        try:
            return ingest_pdf_file(tmp_path)
        finally:
            os.remove(tmp_path)

    # HTML response
    soup = BeautifulSoup(response.content, "html.parser")
    for tag in soup(["script", "style"]):
        tag.decompose()
    return clean_text(soup.get_text(separator="\n"))



def ingest_to_knowledge_base(text: str, metadata: dict = None):
    if not text or len(text) < MIN_LENGTH:
        logger.warning("Skipping short/empty text (%d chars)", len(text))
        return

    kb = get_chroma_collection("knowledge_base")
    kb.add_texts([text], metadatas=[metadata or {}])
    logger.info("Added to knowledge base (%d chars)", len(text))


def ingest_path(path: str):
    ext = os.path.splitext(path)[1].lower()
    if ext == ".txt":
        logger.info("Ingesting TXT: %s", path)
        text = ingest_txt_file(path)
    elif ext == ".pdf":
        logger.info("Ingesting PDF: %s", path)
        text = ingest_pdf_file(path)
    else:
        raise ValueError(f"Unsupported file type: {ext}")

    ingest_to_knowledge_base(text, metadata={"source": path})



def ingest_from_url(url: str, benefit_id: str = None):
    logger.info("Ingesting URL: %s", url)
    text = ingest_url(url)
    metadata = {"source": url}
    if benefit_id:
        metadata["benefit_id"] = benefit_id
    ingest_to_knowledge_base(text, metadata=metadata)

    
def ingest_benefit_sources(benefit_id: str, urls: list[str]):
    for url in urls:
        try:
            ingest_from_url(url, benefit_id=benefit_id)
        except Exception as e:
            logger.error("Error ingesting %s for %s: %s", url, benefit_id, e)


# CLI ENTRYPOINT
if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Ingest files or URLs into the knowledge base (ChromaDB)")
    parser.add_argument("--file", type=str, help="Path to a .pdf or .txt file")
    parser.add_argument("--url", type=str, help="URL to ingest as knowledge")
    parser.add_argument("--folder", type=str, help="Folder path to ingest all .txt/.pdf files recursively") 

    args = parser.parse_args()

    if args.file:
        ingest_path(args.file)
    elif args.url:
        ingest_from_url(args.url)
    elif args.folder:
        for root, _, files in os.walk(args.folder):
            for file in files:
                if file.endswith((".txt", ".pdf")):
                    full_path = os.path.join(root, file)
                    try:
                        ingest_path(full_path)
                    except Exception as e:
                        logger.error("Error with %s: %s", full_path, e)
    else:
        logger.warning("Please provide --file, --url or --folder")
        parser.print_help()
