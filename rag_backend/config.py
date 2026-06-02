import os
from dotenv import load_dotenv
from langchain_groq import ChatGroq
from langchain_huggingface import HuggingFaceEmbeddings

load_dotenv()

GROQ_API_KEY = os.getenv("GROQ_API_KEY")
MODEL_NAME = "llama-3.3-70b-versatile"
CHROMA_DB_PATH = os.getenv("CHROMA_DB_PATH", "./chroma_db")
ENABLE_WEB_SEARCH_FALLBACK = os.getenv("ENABLE_WEB_SEARCH_FALLBACK", "false").lower() == "true"

embeddings = HuggingFaceEmbeddings(
    model_name="sentence-transformers/all-MiniLM-L6-v2"
)

llm = ChatGroq(
    api_key=GROQ_API_KEY,
    model_name=MODEL_NAME,
    temperature=0.7,
)
