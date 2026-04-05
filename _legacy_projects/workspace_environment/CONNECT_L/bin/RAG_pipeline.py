from llama_index.core import VectorStoreIndex, StorageContext, load_index_from_storage
from llama_index.core.query_engine import RetrieverQueryEngine
from llama_index.embeddings.huggingface import HuggingFaceEmbedding
from llama_index.vector_stores.chroma import ChromaVectorStore
import chromadb

# 1. Initialize the Chroma vector store
def initialize_chroma_vector_storage():
    chroma_client = chromadb.PersistentClient(path="~/test/chroma_persist")
    chroma_collection = chroma_client.get_or_create_collection("code_index")
    vector_store = ChromaVectorStore(collection=chroma_collection)
    return vector_store

# 2. recovery StorageContext
def recovery_storage_context(vector_store):
    return StorageContext.from_defaults(vector_store=vector_store)

#3. Load the index from storage
def load_index_from_storage(vector_storage):
    index = VectorStoreIndex.from_vector_store(storage_context=vector_storage)
    return index.as_retriever(similarity_top_k=5)

# 4. Create a query engine
def create_query_engine(retriever):
    return RetrieverQueryEngine(retriever=retriever)
    
vectorStore = initialize_chroma_vector_storage()
storageContext = recovery_storage_context(vectorStore)
retriever = load_index_from_storage(storageContext)
query_engine = create_query_engine(retriever)

# query = "AIDL로 정의된 인터페이스를 사용하는 방법은?"
# retrieved_nodes = query_engine.retrieve(query)

# # 텍스트만 추출
# context = "\n\n".join([node.get_content() for node in retrieved_nodes])

# 사용자로부터 질문 입력 받기
query = input("🔍 궁금한 점을 입력하세요: ")

# 4. Ollama에 보낼 프롬프트 구성
prompt = f"""You are a helpful Android AOSP code assistant. Based on the following code context, answer the question.

--- CODE CONTEXT ---
{context}

--- QUESTION ---
{query}
"""