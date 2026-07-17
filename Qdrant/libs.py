import os
import re
import time
import sys
import httpx
from qdrant_client import AsyncQdrantClient
from qdrant_client.models import PointStruct
from langchain_text_splitters import MarkdownHeaderTextSplitter

def update_vault_index(vault_path):
  new_index = {}
  for root, _, files in os.walk(vault_path):
    for file in files:
      if file.endswith('.md'):
        note_name = os.path.splitext(file)[0]
        new_index[note_name] = os.path.join(root, file)
  return new_index

def resolve_transclusions(content, current_file_path, vault_file_index, visited=None):
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

async def wait_for_qdrant(url, interval=15):
  print(f'>>> Awaiting connection to vector store endpoint at: {url}', file=sys.stderr)
  health_endpoint = f'{url}/healthz'
  async with httpx.AsyncClient() as client:
    while True:
      try:
        response = await client.get(health_endpoint, timeout=2.0)
        if response.status_code == 200:
          print('[SUCCESS] Connected to vector store.', file=sys.stderr)
          break
      except httpx.RequestError:
        pass
      await asyncio.sleep(interval)

async def get_embedding(async_client, text, ai_engine_url, embed_model):
  '''Unified non-blocking embedding extraction factory for MCP and file watchers.'''
  try:
    if ':11434' in ai_engine_url:
      endpoint = f'{ai_engine_url}/api/embed' if not ai_engine_url.endswith('/api/embed') else ai_engine_url
      res = await async_client.post(endpoint, json={'model': embed_model, 'input': text}, timeout=5.0)
      res.raise_for_status()
      output = res.json().get('embeddings', [])
      return output if isinstance(output, list) else output
    else:
      base_url = ai_engine_url.rstrip('/')
      endpoint = f'{base_url}/embeddings' if base_url.endswith('/v1') else f'{base_url}/v1/embeddings'
      res = await async_client.post(endpoint, json={'model': embed_model, 'input': text}, timeout=5.0)
      res.raise_for_status()
      data = res.json()
      # Standard OpenAI schema resolution: data[0].embedding or data.data[0].embedding
      embeddings_list = data.get('data', [{}])
      if embeddings_list and isinstance(embeddings_list, list):
        return embeddings_list[0].get('embedding', [])
      return []
  except Exception as e:
    print(f'[CRITICAL] Embedding extraction collapsed. Trace: {str(e)}', file=sys.stderr)
    return []

def clean_markdown(content):
  content = re.sub(r'^---[\s\S]*?---', '', content)
  content = re.sub(r'\[\[([^\]|#]+)(?:[^\]]*)?\]\]', r'\1', content)
  return content.strip()

async def index_file(file_path, vault_path, collection_name, qdrant_client, async_client, ai_engine_url, embed_model):
  if not file_path.endswith('.md') or not os.path.exists(file_path):
    return
  try:
    vault_file_index = update_vault_index(vault_path)
    with open(file_path, 'r', encoding='utf-8') as f:
      raw_content = f.read()

    expanded_content = resolve_transclusions(raw_content, file_path, vault_file_index)
    cleaned_content = clean_markdown(expanded_content)
    if not cleaned_content:
      return

    headers_to_split_on = [('#', 'Header1'), ('##', 'Header2'), ('###', 'Header3')]
    splitter = MarkdownHeaderTextSplitter(headers_to_split_on=headers_to_split_on)
    chunks = splitter.split_text(cleaned_content)
    points = []

    for i, chunk in enumerate(chunks):
      text_payload = chunk.page_content
      metadata = chunk.metadata.copy()
      metadata['source_file'] = os.path.basename(file_path)

      if not text_payload.strip():
        continue
      vector = await get_embedding(async_client, text_payload, ai_engine_url, embed_model)
      if not vector:
        continue

      point_id = hash(f'{file_path}_{i}_{time.time()}') & 0xFFFFFFFFFFFFFFFF
      points.append(PointStruct(id=point_id, vector=vector, payload={'text': text_payload, 'metadata': metadata}))

    if points:
      await qdrant_client.delete(
        collection_name=collection_name,
        points_selector={'match': {'key': 'metadata.source_file', 'value': os.path.basename(file_path)}}
      )
      await qdrant_client.upsert(collection_name=collection_name, points=points)
      print(f'[SUCCESS] Indexed: {os.path.basename(file_path)}')
  except Exception as e:
    print(f'[ERROR] Failed to index {file_path}: {str(e)}', file=sys.stderr)
