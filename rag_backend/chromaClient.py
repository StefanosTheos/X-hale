import os
from dotenv import load_dotenv
from langchain_chroma import Chroma
import chromadb

from config import embeddings

chromadb.config.Settings.telemetry_enabled = False
load_dotenv()

CHROMA_DB_PATH = os.getenv("CHROMA_DB_PATH", "./chroma_db")
COLLECTION_NAME = os.getenv("CHROMA_COLLECTION_NAME", "knowledge_base")

def get_chroma_collection(name: str = None):
    return Chroma(
        collection_name=name or COLLECTION_NAME,
        embedding_function=embeddings,
        persist_directory=CHROMA_DB_PATH,
    )
