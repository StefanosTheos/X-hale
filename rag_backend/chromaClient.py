import os
from langchain_chroma import Chroma

from config import embeddings

CHROMA_DB_PATH = os.getenv("CHROMA_DB_PATH", "./chroma_db")
COLLECTION_NAME = os.getenv("CHROMA_COLLECTION_NAME", "knowledge_base")

_collections: dict = {}

def get_chroma_collection(name: str = None) -> Chroma:
    key = name or COLLECTION_NAME
    if key not in _collections:
        _collections[key] = Chroma(
            collection_name=key,
            embedding_function=embeddings,
            persist_directory=CHROMA_DB_PATH,
        )
    return _collections[key]
