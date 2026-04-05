from llama_index.core import VectorStoreIndex, ServiceContext, StorageContext, Document
from llama_index.core.node_parser import SentenceSplitter
from llama_index.core.node_parser.text.sentence import SentenceSplitter
from llama_index.core import SimpleDirectoryReader
from llama_index.embeddings.huggingface import HuggingFaceEmbedding
from llama_index.vector_stores.chroma import ChromaVectorStore
from llama_index.core import Settings

import chromadb
from tqdm import tqdm
import logging
import os, subprocess
import hashlib
import json
from concurrent.futures import ThreadPoolExecutor

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

embedding_dirs = [
    # "device",
    # "hardware",
    # "frameworks",
    # "packages",
    # "system",
    # "external",
    
    # "vendor",
    "vendor/mobis/hardware/interfaces/camera",
    # "vendor/mobis/packages/apps",
    
]
documents = []
remote = "svr"
remote_path = "/home/luis/CONNECT/lagvm/LINUX/android"
samba_path = "/home/luis/CONNECT_SOURCES/lagvm/LINUX/android"
extensions = [".java", ".xml", ".kt", ".gradle", ".cpp", ".hpp", ".c", ".h", ".aidl", ".sh", ".mk", ".bp"]
exclude_paths = ["*/out/*", "*/build/*, */.git/*", "*/.idea/*", "*/.gradle/*", "*/.vscode/*", "*/.DS_Store",
                 "*/node_modules/*", "*/tests/*", "*/test/*", "*/tests/*", "*/testcases/*", "*/examples/*",
                 "*/docs/*", "*/doc/*", "*/docs_src/*, */docs_src/*", "*/examples_src/*", "*/samples/*", 
                 "*/sample/*", "*/samples_src/*", "*/src/test/*", "*/src/testcases/*", "*/src/tests/*", 
                 "*/values-*/*", "*/drawable*/*", "*/res/*", "*/assets/*", "*/bin/*", "*/obj/*", 
                 "*/gen/*", "*/generated/*", "*/build/*"]
checkpoint_size = 100
chroma_persist_dir= os.getenv("WORSKSPACE_HOME", "./") + "chroma_persist"
checkpoint_dir = "./checkpoints"
processed_file = os.path.join(checkpoint_dir, "processed_files.json")
MAX_DOC_SIZE = 500 * 1024 # 500KB
error_log_file = "embedding_errors.log"
invalid_files = []

checkpoint_dir = "./checkpoints"
os.makedirs(checkpoint_dir, exist_ok=True)
# extensions = [".java"]

# load checkpointed processed files
if os.path.exists(processed_file):
    try: 
        with open(processed_file, "r") as f:
            processed_files = json.load(f)
    except :
        processed_files = {}
else:
    processed_files = {}
    

print("Starting the embedding process...")

def get_md5_hash(file_path):
    """
    Calculate the MD5 hash of a file.
    """
    hash_md5 = hashlib.md5()
    with open(file_path, "rb") as f:
        for chunk in iter(lambda: f.read(4096), b""):
            hash_md5.update(chunk)
    return hash_md5.hexdigest()

def get_file_list_via_ssh(directory, exts):
    """
    Recursively find all source files in the given directory with specified extensions using SSH.
    """
    # print(f"🔍 소스 파일 검색 시작: {directory} (확장자: {exts})")

    ext_filters = " -o ".join([f"-iname '*{ext}'" for ext in exts])
    ext_paths = " ".join([f"-not -path '{path}'" for path in exclude_paths])
    find_cmd = f"find {remote_path}/{directory} -type f \\( {ext_filters} \\) {ext_paths}"  
        
    ssh_cmd = ["ssh", remote, find_cmd]
    
    # print(f"🔍 파일 검색 명령어: {' '.join(ssh_cmd)}")
    result = subprocess.run(ssh_cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    file_list = []
    if result.returncode != 0:
        print(f"❗ 오류 발생: {result.stderr}")
        
    else :
        file_list = result.stdout.strip().split('\n')
        print(f"✅ 파일 검색 완료: {len(file_list)}개 파일 발견")
    return file_list

def convert_remote_path_to_samba_path(paths):
    """
    Convert a remote file path to a Samba path.
    """
    # if path.startswith(remote_path):
    #     return samba_path + path[len(remote_path):]
    # return path
    return [path.replace(remote_path, samba_path) for path in paths if path.strip()]

def find_source_files_by_find(directory, extensions):
    """
    Recursively find all source files in the given directory with specified extensions using the `find` command.
    """
    print(f"🔍 소스 파일 검색 시작: {directory} (확장자: {extensions})")
    # find_cmd = f"find {directory} -type f {' '.join(["f"-iname *{ext}" for ext in extensions])}"
    # find_cmd = f"find {directory} -type f \\( " 
    # +  sum([["-iname", f"*{ext}", "-o"] for ext in extensions], [])[:-1] + "\\)"
    find_cmd = [
        "find", directory, "-type", "f",
        "(",
        *sum([["-iname", f"*{ext}", "-o"] for ext in extensions], [])[:-1],
        ")"
    ]
    
    
    print(f"🔍 파일 검색 명령어: {find_cmd}")
    result = subprocess.run(find_cmd, stdout=subprocess.PIPE, text=True)
    
    if result.returncode != 0:
        print(f"❗ 오류 발생: {result.stderr}")
        return []
    
    files = result.stdout.strip().split('\n')
    for file in files:
        if file:  # 빈 문자열 체크
            print(f"🔍 발견된 파일: {file}")
            yield file
def find_source_files(directory, extensions):
    # """
    # Recursively find all source files in the given directory with specified extensions.
    # """
    # import os
    # source_files = []
    # for root, _, files in os.walk(directory):
    #     for file in files:
    #         if file.endswith(tuple(extensions)):
    #             source_files.append(os.path.join(root, file))
    # return source_files
    print(f"🔍 소스 파일 검색 시작: {directory} (확장자: {extensions})")
    for root, dirs, files in os.walk(directory):
        for file in files:
            if any(file.endswith(ext) for ext in extensions):
                print(f"🔍 발견된 파일: {os.path.join(root, file)}")
                yield os.path.join(root, file)

def read_files_as_documents(filepaths):
    """
    Read files from the given file paths and return a list of Document objects.
    """
    
    docs = []
    for filepath in tqdm(filepaths, desc="📂 디렉토리 읽는 중"):
        file_hash = get_md5_hash(filepath)
        if file_hash and processed_files.get(filepath) == file_hash:
            continue
        # logging.info(f"processing {filepath} new/changed files")
        text = is_valid_text_file(filepath)
        processed_files[filepath] = file_hash  # 파일 해시를 processed_files에 추가
        if text is not None and text is not False:
            docs.append(Document(text=text, metadata={"file_path": filepath}))
        else:
            invalid_files.append(filepath)
    
    return docs

def is_valid_text_file(filepath, max_size=MAX_DOC_SIZE):
    """
    Check if the file is a valid text file.
    """
    try:
        with open(filepath, "r", encoding="utf-8", errors="ignore") as f:
            # 파일 크기 체크
            text = f.read()
            if not isinstance(text, str) or len(text.strip()) == 0:
                raise ValueError(f"파일이 비어있거나 유효하지 않음: {filepath}")
            
            if len(text) > max_size:
                raise ValueError(f"파일 크기가 너무 큼: {filepath} ({len(text)} bytes)")
            
            return text
    except Exception as e:
        return False


# 3. 임베딩 모델 설정 + Settings 등록
embed_model = HuggingFaceEmbedding(model_name="BAAI/bge-small-en-v1.5")
Settings.embed_model = embed_model  # ✅ 최신 방식: ServiceContext 제거

# 4. 벡터 스토어 설정
chroma_client = chromadb.PersistentClient(
    path=chroma_persist_dir,
    # settings=chromadb.Settings(
    #     chroma_db_impl="duckdb+parquet",
    #     persist_directory=chroma_persist_dir,
    #     persist=True,
    # )
)

chroma_collection = chroma_client.get_or_create_collection("code_index")
vector_store = ChromaVectorStore(chroma_collection=chroma_collection)
storage_context = StorageContext.from_defaults(vector_store=vector_store)

# 2. Chunking
parser = SentenceSplitter(chunk_size=512, chunk_overlap=50)
all_nodes = []

for embedding_dir in embedding_dirs:
    print(f"📂 디렉토리 탐색 중: {embedding_dir}")
    # Find source files using the find command
    # source_files = find_source_files_by_find(embedding_dir, [".java", ".xml", ".kt", ".gradle", ".cpp", ".hpp", ".c", ".h", ".aidl", ".sh", ".mk", ".bp"])
    invalid_files = []
    file_list = get_file_list_via_ssh(embedding_dir, extensions)
    if not os.environ.get("SSH_CLIENT"):
        source_files = convert_remote_path_to_samba_path(file_list)
    else:
        source_files = file_list
        
    
    with ThreadPoolExecutor(max_workers=6) as executor:
        # 1. 파일 읽기
        print(f"📂 {embedding_dir} 디렉토리에서 파일 읽는 중...")
        # raw_docs = list(executor.map(is_valid_text_file, source_files))
        raw_docs = read_files_as_documents(source_files)
        
        if invalid_files:
            print(f"❗ 경고: 유효하지 않은 파일 발견: {len(invalid_files)}개")
            with open(error_log_file, "a") as f:
                for file in invalid_files:
                    f.write(f"{file}\n")
            print(f"❗ 오류 로그가 {error_log_file}에 저장되었습니다.")
            
        nodes = []
        for doc in tqdm(raw_docs, desc=f"📦 {embedding_dir} 문서 Chunking 중"):
            if not isinstance(doc.text, str) or len(doc.text.strip()) == 0:
                print(f"❗ 경고: 빈 문서 발견, 건너뜁니다: {doc.metadata.get('file_path', '알 수 없는 파일')}")
                continue
            try:
                text = doc.text.strip()  # 텍스트 앞뒤 공백 제거
                chunks = parser.split_text(text)
                nodes.append(doc)
                nodes.extend([Document(text=chunk, metadata=doc.metadata) for chunk in chunks if isinstance(chunk, str)])
            except Exception as e:
                print(f"❗ 오류 발생: {e.with_traceback} (파일: {doc.metadata.get('file_path', '알 수 없는 파일')})")
                continue
            
        print(f"🧠 총 Chunk 수: {len(nodes)}")
        if nodes:
            # 5. 인덱스 생성
            print("🛠️ 인덱스 생성 중...")
            index = VectorStoreIndex.from_documents(
                nodes,
                storage_context=storage_context,
                show_progress=True,
                checkpoint_size=checkpoint_size,
            )
            print("✅ 인덱스 생성 완료!")
        
            # Checkpointing processed files
        with open(processed_file, "w") as f:
            json.dump(processed_files, f)

