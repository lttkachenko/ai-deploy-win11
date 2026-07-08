import os
import re
import time
import sys
import argparse
import requests
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler
from qdrant_client import QdrantClient
from qdrant_client.models import Distance, VectorParams, PointStruct
from langchain_text_splitters import MarkdownHeaderTextSplitter

parser = argparse.ArgumentParser(description='Gheimher Multi-Vault Automated RAG Watcher')
parser.add_argument('--vault', type=str, required=True, help='Absolute path to target Vault')
parser.add_argument('--collection', type=str, required=True, help='Target Qdrant collection name')
parser.add_argument('--port', type=int, default=6333, help='Local Qdrant HTTP port')
args = parser.parse_args()

VAULT_PATH = os.path.abspath(args.vault)
COLLECTION_NAME = args.collection
QDRANT_PORT = args.port

QDRANT_URL = f'http://127.0.0.1:{QDRANT_PORT}'
OLLAMA_URL = 'http://127.0.0'
EMBED_MODEL = 'nomic-embed-text'
VECTOR_SIZE = 768

vault_file_index = {}

def update_vault_index(vault_path):
  global vault_file_index
  new_index = {}
  for root, _, files in os.walk(vault_path):
    for file in files:
      if file.endswith('.md'):
        note_name = os.path.splitext(file)[0]
        new_index[note_name] = os.path.join(root, file)
  vault_file_index = new_index

def resolve_transclusions(content, current_file_path, visited=None):
  if visited is None:
    visited = set()
  abs_current_path = os.path.abspath(current_file_path)
  if abs_current_path in visited:
    return ''

  visited.add(abs_current_path)
  transclusion_pattern = r'!\[\[([^\]|#]+)(?:#[^\]]*)?\]\]'

  def replace_match(match):
    note_name = match.group(1).strip()
    target_path = vault_file_index.get(note_name)

    if target_path and os.path.exists(target_path):
      try:
        with open(target_path, 'r', encoding='utf-8') as f:
          child_content = f.read()
        child_content = re.sub(r'^---[\s\S]*?---', '', child_content).strip()
        return resolve_transclusions(child_content, target_path, visited.copy())
      except Exception:
        return f'\n[ERROR: Failed to resolve transclusion for {note_name}]\n'
    return match.group(0)
  return re.sub(transclusion_pattern, replace_match, content)

def wait_for_qdrant(url, interval=15):
  print(f'>>> Awaiting connection to vector store endpoint at: {url}', file=sys.stderr)
  health_endpoint = f'{url}/healthz'
  while True:
    try:
      response = requests.get(health_endpoint, timeout=2)
      if response.status_code == 200:
        print('[SUCCESS] Connected to Qdrant node.', file=sys.stderr)
        break
    except requests.RequestException:
      pass
    time.sleep(interval)

def get_embedding(text):
  response = requests.post(OLLAMA_URL, json={'model': EMBED_MODEL, 'input': text})
  response.raise_for_status()
  return response.json()['embeddings']

def clean_markdown(content):
  content = re.sub(r'^---[\s\S]*?---', '', content)
  content = re.sub(r'\[\[([^\]|#]+)(?:[^\]]*)?\]\]', r'\1', content)
  return content.strip()

def index_file(file_path):
  if not file_path.endswith('.md'):
    return
  try:
    update_vault_index(VAULT_PATH)
    with open(file_path, 'r', encoding='utf-8') as f:
      raw_content = f.read()

    expanded_content = resolve_transclusions(raw_content, file_path)
    cleaned_content = clean_markdown(expanded_content)
    if not cleaned_content:
      return

    headers_to_split_on = [('#', 'Header1'), ('##', 'Header2'), ('###', 'Header3')]
    splitter = MarkdownHeaderTextSplitter(headers_to_split_on=headers_to_split_on)
    chunks = splitter.split_text(cleaned_content)
    points = []

    for i, chunk in enumerate(chunks):
      text_payload = chunk.page_content
      metadata = chunk.metadata
      metadata['source_file'] = os.path.basename(file_path)

      if not text_payload.strip():
        continue
      vector = get_embedding(text_payload)
      point_id = hash(f'{file_path}_{i}_{time.time()}') & 0xFFFFFFFFFFFFFFFF

      points.append(PointStruct(id=point_id, vector=vector, payload={'text': text_payload, 'metadata': metadata}))

    if points:
      qdrant_client.delete(
        collection_name=COLLECTION_NAME,
        points_selector={'match': {'key': 'metadata.source_file', 'value': os.path.basename(file_path)}}
      )
      qdrant_client.upsert(collection_name=COLLECTION_NAME, points=points)
      print(f"[SUCCESS] Collection '{COLLECTION_NAME}' indexed: {os.path.basename(file_path)}")
  except Exception as e:
    print(f'[ERROR] Failed to index {file_path}: {str(e)}', file=sys.stderr)

class ObsidianHandler(FileSystemEventHandler):
  def on_modified(self, event):
    if not event.is_directory: index_file(event.src_path)
  def on_created(self, event):
    if not event.is_directory: index_file(event.src_path)

if __name__ == '__main__':
  if not os.path.exists(VAULT_PATH):
    print(f'[CRITICAL] Specified vault path does not exist: {VAULT_PATH}', file=sys.stderr)
    sys.exit(1)

  wait_for_qdrant(QDRANT_URL, interval=15)
  qdrant_client = QdrantClient(url=QDRANT_URL)

  try:
    qdrant_client.get_collection(COLLECTION_NAME)
  except Exception:
    qdrant_client.create_collection(
      collection_name=COLLECTION_NAME,
      vectors_config=VectorParams(size=VECTOR_SIZE, distance=Distance.COSINE),
    )

  update_vault_index(VAULT_PATH)
  print(f">>> Daemon active. Target: Space '[{COLLECTION_NAME}]' -> Vault '{VAULT_PATH}'")

  event_handler = ObsidianHandler()
  observer = Observer()
  observer.schedule(event_handler, path=VAULT_PATH, recursive=True)
  observer.start()
  try:
    while True: time.sleep(1)
  except KeyboardInterrupt:
    observer.stop()
  observer.join()
