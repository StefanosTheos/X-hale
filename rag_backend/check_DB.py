from chromaClient import get_chroma_collection
import json

def inspect_knowledge_base():
    kb = get_chroma_collection("knowledge_base")

    all_data = kb.get(include=['documents', 'metadatas'])
    documents = all_data['documents']
    metadatas = all_data['metadatas']

    print(f"Total entries in KB: {len(documents)}\n")

    for idx, (doc, metadata) in enumerate(zip(documents, metadatas), start=1):
        print(f"Entry #{idx}")
        print(f"Metadata: {json.dumps(metadata, indent=2)}")
        snippet = doc[:300] + ('...' if len(doc) > 300 else '')
        print(f"Document snippet: {snippet}\n")
        print("-" * 80)

if __name__ == "__main__":
    inspect_knowledge_base()
