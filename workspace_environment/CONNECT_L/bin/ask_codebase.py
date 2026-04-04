from llama_index.core import VectorStoreIndex, StorageContext, load_index_from_storage, Settings
from llama_index.embeddings.huggingface import HuggingFaceEmbedding
from llama_index.core.query_engine import RetrieverQueryEngine
from llama_index.vector_stores.chroma import ChromaVectorStore
import chromadb
import requests

persist_dir = "/home/luis/test/chroma_persist"
Settings.embed_model = HuggingFaceEmbedding(model_name="BAAI/bge-small-en-v1.5")
# This script initializes a Chroma vector store, retrieves relevant code context based on user queries,
# and uses the Ollama API to generate answers based on that context.


# 1. Initialize the Chroma vector store
def initialize_chroma_vector_storage():
    chroma_client = chromadb.PersistentClient(path=persist_dir)
    chroma_collection = chroma_client.get_or_create_collection("code_index")
    vector_store = ChromaVectorStore(chroma_collection=chroma_collection)
    return vector_store

# # 2. recovery StorageContext
# def recovery_storage_context(vector_store):
#     return StorageContext.from_defaults(vector_store=vector_store)

#3. Load the index from storage
def load_index_from_storage(vector_storage_context):
    # index = VectorStoreIndex.from_vector_store(storage_context=vector_storage)
    index = VectorStoreIndex.from_vector_store(vector_store=vector_storage_context)
    return index.as_retriever(similarity_top_k=5)

# 4. Create a query engine
def create_query_engine(retriever):
    return RetrieverQueryEngine(retriever=retriever)
    
vectorStore = initialize_chroma_vector_storage()
# storageContext = recovery_storage_context(vectorStore)
retriever = load_index_from_storage(vectorStore)
query_engine = create_query_engine(retriever)


# 2. 사용자 질의 받기
query = input("🔍 궁금한 점을 입력하세요: ")

# 3. 유사한 문서 검색
retrieved_nodes = query_engine.retrieve(query)
context = "\n\n".join([node.get_content() for node in retrieved_nodes])

# 4. Ollama에 보낼 프롬프트 구성
prompt = f"""You are a helpful Android AOSP code assistant. Based on the following code context, answer the question.

--- CODE CONTEXT ---
{context}

--- QUESTION ---
{query}
"""

# 5. Ollama API 호출 (localhost:11434)
def ask_ollama(prompt, model="llama3"):
    url = "http://localhost:11434/api/generate"
    headers = {"Content-Type": "application/json"}
    payload = {
        "model": model,
        "prompt": prompt,
        "stream": False
    }
    res = requests.post(url, headers=headers, json=payload)
    return res.json().get("response", "답변을 생성하지 못했습니다.")

# 6. 답변 출력
answer = ask_ollama(prompt)
print("\n🧠 Ollama의 답변:\n")
print(answer)