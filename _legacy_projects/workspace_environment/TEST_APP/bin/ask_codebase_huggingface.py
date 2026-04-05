from llama_index.core import (
    VectorStoreIndex, StorageContext, load_index_from_storage, Settings
)
from llama_index.embeddings.huggingface import HuggingFaceEmbedding
import requests
import json


# 1. Initialize the HuggingFace embedding
def initialize_huggingface_embedding():
    embedding = HuggingFaceEmbedding(model_name="sentence-transformers/all-MiniLM-L6-v2")
    return embedding

# 2. load the index from storage
def load_index_from_storage():
    storage_context = StorageContext.from_defaults(
        embedding=initialize_huggingface_embedding(),
        persist_dir="~/test/chroma_persist"
    )
    index = VectorStoreIndex([], storage_context=storage_context)
    return index.as_retriever(similarity_top_k=5)