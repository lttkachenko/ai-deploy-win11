# .\Qdrant\libs.py - Async RAG Vector Core Engine
# Style Enforced: Spaces 2, LF, SingleQuotes, Strict Quality Control
# Single Source of Truth Alignment: Strong type compliance with modern Qdrant SDK

import os
import re
import sys
import asyncio
import hashlib
import urllib.request
from qdrant_client import AsyncQdrantClient
from qdrant_client.models import PointStruct, Filter, FieldCondition, MatchValue, FilterSelector
from langchain_text_splitters import MarkdownHeaderTextSplitter

# --- Single Source of Truth for Models & Dimension Space ---
VECTOR_SIZE = 768
EMBED_MODEL_NAME = 'nomic-ai/nomic-embed-text-v1.5'

# Global reference slot for TS-like lazy initialization
embedding_engine = None


def update_vault_index(vault_path: str) -> dict:
  """Recursively compile flat document name map to track deep markdown file targets."""
  new_index = {}
  for root, _, files in os.walk(vault_path):
    for file in files:
      if file.endswith('.md'):
        note_name = os.path.splitext(file)[0]
        new_index[note_name] = os.path.join(root, file)
  return new_index


def resolve_transclusions(content: str, current_file_path: str, vault_file_index: dict, visited=None) -> str:
  """Recursively resolve abstract Obsidian transclusion links into compiled textual layouts."""
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
  base_url = url.rstrip('/')
  health_endpoint = f'{base_url}/healthz'

  while True:
    try:
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
  global embedding_engine
  try:
    # --- DOS-12 TS-Like Lazy Destruction Import Matrix ---
    # Torch and SentenceTransformer are only loaded into memory when required by active computations
    if embedding_engine is None:
      print('>>> [LAZY BOOT] Initializing Shared CPU Transformer Model [nomic-embed-text]...', file=sys.stderr)
      from sentence_transformers import SentenceTransformer
      embedding_engine = SentenceTransformer(EMBED_MODEL_NAME, device='cpu')
      print('[SUCCESS] Shared Python inference layer loaded on CPU boundary.', file=sys.stderr)

    prefix = 'search_query: ' if is_query else 'search_document: '
    prefixed_text = prefix + text

    vector = await asyncio.to_thread(lambda: embedding_engine.encode(prefixed_text).tolist())
    return vector
  except Exception as e:
    print(f'[CRITICAL] Local CPU embedding extraction collapsed. Trace: {str(e)}', file=sys.stderr)
    return []


def clean_markdown(content: str) -> str:
  """Strip yaml frontmatter blocks and convert inner wiki-links safely without super-linear tracking traps."""
  content = re.sub(r'^---[\s\S]*?---', '', content)
  content = re.sub(r'\[\[([^\]|]+)(?:\|[^\]]*)?\]\]', r'\1', content)
  return content.strip()


def detect_language(text: str) -> str:
  """Deterministic character subset analysis routing document text metadata payloads."""
  if bool(re.search('[а-яА-ЯёЁ]', text)):
    return 'ru'
  return 'en'


async def index_file(file_path: str, vault_path: str, collection_name: str, qdrant_client: AsyncQdrantClient):
  """Parse text blocks asynchronously, compute vectors via threads, and synchronize with Qdrant clusters."""
  if not file_path.endswith('.md'):
    return

  try:
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

    chunks = await asyncio.to_thread(sync_file_parsing_pipeline)

    # Calculate unified relative path strings and directory tokens matching REST-like conventions
    relative_raw_path = os.path.relpath(file_path, vault_path)
    uri_path = os.path.splitext(relative_raw_path)[0].replace('\\', '/')
    parent_path = os.path.dirname(uri_path)

    if chunks is None:
      await qdrant_client.delete(
        collection_name=collection_name,
        points_selector=FilterSelector(
          filter=Filter(
            must=[
              FieldCondition(
                key='metadata.uri_path',
                match=MatchValue(value=uri_path)
              )
            ]
          )
        )
      )
      print(f'[PURGED] Removed obsolete vectors for deleted file URI: {uri_path}')
      return

    if not chunks:
      return

    points = []
    for i, chunk in enumerate(chunks):
      text_payload = chunk.page_content
      metadata = chunk.metadata.copy()

      # Inject precise architectural parameters according to DOS-12 layout compliance rules
      metadata['source_file'] = os.path.basename(file_path)
      metadata['uri_path'] = uri_path
      metadata['parent_path'] = parent_path
      metadata['lang'] = detect_language(text_payload)

      if not text_payload.strip():
        continue

      vector = await get_embedding(text_payload, is_query=False)
      if not vector:
        continue

      # Cryptographic SHA-256 identifier cast guarantees record uniqueness across restarts
      seed_string = f'{file_path}_{i}'
      hash_hex = hashlib.sha256(seed_string.encode('utf-8')).hexdigest()
      point_id = int(hash_hex[:16], 16)

      points.append(PointStruct(id=point_id, vector=vector, payload={'text': text_payload, 'metadata': metadata}))

    if points:
      await qdrant_client.delete(
        collection_name=collection_name,
        points_selector=FilterSelector(
          filter=Filter(
            must=[
              FieldCondition(
                key='metadata.uri_path',
                match=MatchValue(value=uri_path)
              )
            ]
          )
        )
      )
      await qdrant_client.upsert(collection_name=collection_name, points=points)
      print(f'[SUCCESS] Indexed URI: {uri_path} (Parent: /{parent_path if parent_path else "root"})')

  except Exception as e:
    print(f'[ERROR] Failed to index {file_path}: {str(e)}', file=sys.stderr)
