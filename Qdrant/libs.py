import os
import re
import sys
import asyncio
import urllib.request
from qdrant_client import AsyncQdrantClient
from qdrant_client.models import PointStruct
from langchain_text_splitters import MarkdownHeaderTextSplitter
from sentence_transformers import SentenceTransformer

# --- Single Source of Truth for Models and Database Layouts ---
COLLECTION_NAME = 'obsidian_knowledge'
VECTOR_SIZE = 768
EMBED_MODEL_NAME = 'nomic-ai/nomic-embed-text-v1.5'

print('>>> Initializing Shared CPU Transformer Model [nomic-embed-text]...', file=sys.stderr)
embedding_engine = SentenceTransformer(EMBED_MODEL_NAME, device='cpu')
print('[SUCCESS] Shared Python inference layer loaded on CPU boundary.', file=sys.stderr)


def update_vault_index(vault_path: str) -> dict:
  new_index = {}
  for root, _, files in os.walk(vault_path):
    for file in files:
      if file.endswith('.md'):
        note_name = os.path.splitext(file)[0]
        new_index[note_name] = os.path.join(root, file)
  return new_index


def resolve_transclusions(content: str, current_file_path: str, vault_file_index: dict, visited=None) -> str:
  if visited is None:
    visited = set()
  abs_current_path = os.path.abspath(current_file_path)
  if abs_current_path in visited:
    return ''
  visited.add(abs_current_path)
  pattern = r'!\[\[([^\]|#]+)(?:#[^\]]*)?\]\]'

  def replace_match(match):
    note_name = match.group(1).strip()
    target_path = vault_file_index.get(note_name)
    if target_path and os.path.exists(target_path):
      try:
        with open(target_path, 'r', encoding='utf-8') as f:
          child_content = f.read()
        child_content = re.sub(r'^---[\s\S]*?---', '', child_content).strip()
        return resolve_transclusions(child_content, target_path, vault_file_index, visited.copy())
      except Exception:
        return f'\n[ERROR: Failed to resolve transclusion for {note_name}]\n'
    return match.group(0)
  return re.sub(pattern, replace_match, content)


async def wait_for_qdrant(url: str, interval=5):
  """Block execution until the target Qdrant container exposes responsive HTTP state endpoints."""
  print(f'>>> Awaiting connection to vector store endpoint at: {url}', file=sys.stderr)
  health_endpoint = f'{url}/healthz'.replace('127.0.0.1', 'localhost')

  while True:
    try:
      # Native lightweight polling block to eliminate external library footprint constraints
      await asyncio.to_thread(lambda: urllib.request.urlopen(health_endpoint, timeout=2.0))
      print('[SUCCESS] Vector store handshake verified. Moving to operational lifecycle.', file=sys.stderr)
      break
    except Exception:
      print(f' |-- [AWAIT] Vector store node unreachable. Retrying socket hook in {interval}s...', file=sys.stderr)
      await asyncio.sleep(interval)


def get_qdrant_client(endpoint_url: str) -> AsyncQdrantClient:
  """Factory pattern instance initialization for isolated Qdrant vector links."""
  return AsyncQdrantClient(url=endpoint_url)


async def get_embedding(text: str, is_query: bool = False) -> list:
  """Unified local CPU-backed embedding factory complying with Nomic v1.5 specifications."""
  try:
    # Nomic v1.5 API model compliance formatting rules injection
    prefix = 'search_query: ' if is_query else 'search_document: '
    prefixed_text = prefix + text

    # Safely offload heavy CPU tensor calculations to a separate thread boundary
    # This prevents the synchronous .encode() from blocking the global async event loop
    vector = await asyncio.to_thread(lambda: embedding_engine.encode(prefixed_text).tolist())
    return vector
  except Exception as e:
    print(f'[CRITICAL] Local CPU embedding extraction collapsed. Trace: {str(e)}', file=sys.stderr)
    return []


def clean_markdown(content: str) -> str:
  content = re.sub(r'^---[\s\S]*?---', '', content)
  content = re.sub(r'\[\[([^\]|#]+)(?:[^\]]*)?\]\]', r'\1', content)
  return content.strip()


def detect_language(text: str) -> str:
  if bool(re.search('[а-яА-ЯёЁ]', text)):
    return 'ru'
  return 'en'


async def index_file(file_path: str, vault_path: str, collection_name: str, qdrant_client: AsyncQdrantClient):
  """Parse text blocks asynchronously, compute vectors via threads, and synchronize with Qdrant clusters."""
  if not file_path.endswith('.md'):
    return

  try:
    # Encapsulate all synchronous filesystem I/O operations into a dedicated isolated worker thread
    def sync_file_parsing_pipeline():
      if not os.path.exists(file_path):
        return None
      with open(file_path, 'r', encoding='utf-8') as f:
        raw_content = f.read()

      vault_file_index = update_vault_index(vault_path)
      expanded_content = resolve_transclusions(raw_content, file_path, vault_file_index)
      cleaned_content = clean_markdown(expanded_content)

      if not cleaned_content:
        return []

      headers_to_split_on = [('#', 'Header1'), ('##', 'Header2'), ('###', 'Header3')]
      splitter = MarkdownHeaderTextSplitter(headers_to_split_on=headers_to_split_on)
      return splitter.split_text(cleaned_content)

    # Execute disk I/O and markdown splitting off the main event loop thread
    chunks = await asyncio.to_thread(sync_file_parsing_pipeline)

    # If chunks returns None, it indicates a strict file deletion event sequence
    if chunks is None:
      await qdrant_client.delete(
        collection_name=collection_name,
        points_selector={'match': {'key': 'metadata.source_file', 'value': os.path.basename(file_path)}}
      )
      print(f'[PURGED] Removed obsolete vectors for deleted file: {os.path.basename(file_path)}')
      return

    if not chunks:
      return

    points = []
    for i, chunk in enumerate(chunks):
      text_payload = chunk.page_content
      metadata = chunk.metadata.copy()
      metadata['source_file'] = os.path.basename(file_path)

      if not text_payload.strip():
        continue

      # Fully async safe token generation block executed on separate system thread clusters
      vector = await get_embedding(text_payload, is_query=False)
      if not vector:
        continue

      # Fixed deterministic identity map generation to intercept mutation tracking collisions
      point_id = hash(f'{file_path}_{i}') & 0xFFFFFFFFFFFFFFFF
      points.append(PointStruct(id=point_id, vector=vector, payload={'text': text_payload, 'metadata': metadata}))

    if points:
      # Clear obsolete state records non-blockingly to eliminate double-indexing collisions
      await qdrant_client.delete(
        collection_name=collection_name,
        points_selector={'match': {'key': 'metadata.source_file', 'value': os.path.basename(file_path)}}
      )
      await qdrant_client.upsert(collection_name=collection_name, points=points)
      print(f'[SUCCESS] Indexed: {os.path.basename(file_path)}')

  except Exception as e:
    print(f'[ERROR] Failed to index {file_path}: {str(e)}', file=sys.stderr)

