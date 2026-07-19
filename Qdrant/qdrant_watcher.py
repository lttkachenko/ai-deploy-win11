import os
import re
import asyncio
from watchfiles import awatch
from qdrant_client.models import Distance, VectorParams

# Import shared enterprise data components matching single source of truth rules
import libs

# --- Configuration Constants ---
VAULT_PATH = r'C:\Path\To\Your\Obsidian\Vault'
QDRANT_LOCAL_URL = 'http://127.0.0.1:6333'

# Host-to-container loop client initialization
qdrant_client = libs.get_qdrant_client(QDRANT_LOCAL_URL)
vault_file_index = {}


def update_vault_index(vault_path: str):
  """Scan and map absolute indexing coordinates inside target vault."""
  global vault_file_index
  new_index = {}
  for root, _, files in os.walk(vault_path):
    for file in files:
      if file.endswith('.md'):
        note_name = os.path.splitext(file)[0]
        new_index[note_name] = os.path.join(root, file)
  vault_file_index = new_index


def resolve_transclusions(content: str, current_file_path: str, vault_file_index: dict, visited=None) -> str:
  """Recursively assemble nested note components to prevent content truncation."""
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
        return resolve_transclusions(child_content, target_path, vault_file_index, visited.copy())
      except Exception:
        return f'\n[ERROR: Failed to resolve transclusion for {note_name}]\n'
    return match.group(0)

  return re.sub(transclusion_pattern, replace_match, content)


def clean_markdown(content: str) -> str:
  """Normalize Obsidian structural parameters and strip raw metadata frontmatter blocks."""
  content = re.sub(r'^---[\s\S]*?---', '', content)
  content = re.sub(r'\[\[([^\]|#]+)(?:[^\]]*)?\]\]', r'\1', content)
  return content.strip()


async def run_async_watcher():
  """Asynchronous loop entry point monitoring filesystem mutations via Rust backend layers."""

  # Step 1: Enforce non-blocking background connection verification lock via shared libs async factory
  await libs.wait_for_qdrant(QDRANT_LOCAL_URL, interval=5)

  # Step 2: Validate target collection schema layout is instantiated
  try:
    await qdrant_client.get_collection(libs.COLLECTION_NAME)
  except Exception:
    await qdrant_client.create_collection(
      collection_name=libs.COLLECTION_NAME,
      vectors_config=VectorParams(size=libs.VECTOR_SIZE, distance=Distance.COSINE),
    )
    print(f'[INIT] Scaffolded pristine schema storage bucket: {libs.COLLECTION_NAME}')

  update_vault_index(VAULT_PATH)
  print(f'\n[ONLINE] Graph-Aware Async RAG Daemon listening on: {VAULT_PATH}')

  # Step 3: Trigger reactive stream capture loop using rust-backed awatch core engine
  async for changes in awatch(VAULT_PATH):
    for change_type, file_path in changes:
      # Pass structural mutation paths directly into the optimized libs indexer pipeline
      await libs.index_file(
        file_path=file_path,
        vault_path=VAULT_PATH,
        collection_name=libs.COLLECTION_NAME,
        qdrant_client=qdrant_client
      )


if __name__ == '__main__':
  asyncio.run(run_async_watcher())
