# .\Qdrant\qdrant_watcher.py - Graph-Aware Async RAG Filesystem Monitor
# Style Enforced: Spaces 2, LF, SingleQuotes, Strict Quality Control
# Single Source of Truth Alignment: Synchronized with declarative mcp.conf.yml metadata

import os
import sys
import asyncio
from watchfiles import awatch
from qdrant_client.models import Distance, VectorParams

current_runtime_dir = os.path.dirname(os.path.abspath(__file__))
if current_runtime_dir not in sys.path:
  sys.path.insert(0, current_runtime_dir)

import libs

def load_mcp_stack_config() -> dict:
  """Parse centralized yaml context deployment schema via robust stream processing."""
  ai_config_env = os.environ.get('AI_CONFIG_PATH')
  if ai_config_env and os.path.exists(ai_config_env):
    config_path = ai_config_env
  else:
    config_path = os.path.abspath(os.path.join(current_runtime_dir, '..', '..', '.ai', 'conf', 'mcp.conf.yml'))
    if not os.path.exists(config_path):
      config_path = r'C:\Users\gadeshi\.ai\conf\mcp.conf.yml'

  default_config = {
    'qdrant_url': 'http://localhost:8093',
    'collection_name': 'db-dev',
    'vault_path': 'D:\\Obsidian\\Vaults\\v-dev'
  }

  if not os.path.exists(config_path):
    print(f'[WARNING] Stack configuration matrix missing at: {config_path}. Using safe fallbacks.', file=sys.stderr)
    return default_config

  detected_url = default_config['qdrant_url']
  collection_name = default_config['collection_name']
  vault_path = default_config['vault_path']

  try:
    with open(config_path, 'r', encoding='utf-8') as f:
      for line in f:
        clean_line = line.strip()
        if not clean_line or clean_line.startswith('#') or ':' not in clean_line:
          continue

        key, val = [raw.strip().strip("'\"") for raw in clean_line.split(':', 1)]

        if key == 'store':
          detected_url = val
        elif key == 'db':
          collection_name = val
        elif key == 'vault':
          vault_path = val

  except Exception as e:
    print(f'[ERROR] Failed to extract tokens from mcp.conf.yml for watcher: {str(e)}. Using fallbacks.', file=sys.stderr)

  return {
    'qdrant_url': detected_url,
    'collection_name': collection_name,
    'vault_path': vault_path
  }


runtime_env = load_mcp_stack_config()
QDRANT_LOCAL_URL = runtime_env['qdrant_url']
COLLECTION_NAME = runtime_env['collection_name']
VAULT_PATH = runtime_env['vault_path']

qdrant_client = libs.get_qdrant_client(QDRANT_LOCAL_URL)


async def run_async_watcher():
  """Asynchronous loop entry point monitoring filesystem mutations via Rust backend layers."""
  await libs.wait_for_qdrant(QDRANT_LOCAL_URL, interval=5)

  try:
    await qdrant_client.get_collection(COLLECTION_NAME)
  except Exception:
    await qdrant_client.create_collection(
      collection_name=COLLECTION_NAME,
      vectors_config=VectorParams(size=libs.VECTOR_SIZE, distance=Distance.COSINE),
    )
    print(f'[INIT] Scaffolded pristine schema storage bucket: {COLLECTION_NAME}', file=sys.stderr)

  print(f'\n[HYDRATE] Triggering manual historical scan for: {VAULT_PATH}', file=sys.stderr)

  for root, _, files in os.walk(VAULT_PATH):
    for file in files:
      if file.endswith('.md'):
        full_file_path = os.path.join(root, file)
        await libs.index_file(
          file_path=full_file_path,
          vault_path=VAULT_PATH,
          collection_name=COLLECTION_NAME,
          qdrant_client=qdrant_client
        )

  print(f'[SUCCESS] Vault hydration completed. Syncing real-time mutations...', file=sys.stderr)
  print(f'\n[ONLINE] Graph-Aware Async RAG Daemon listening on: {VAULT_PATH}', file=sys.stderr)

  async for changes in awatch(VAULT_PATH):
    for change_type, file_path in changes:
      await libs.index_file(
        file_path=file_path,
        vault_path=VAULT_PATH,
        collection_name=COLLECTION_NAME,
        qdrant_client=qdrant_client
      )


if __name__ == '__main__':
  try:
    asyncio.run(run_async_watcher())
  except KeyboardInterrupt:
    print('\n[OFFLINE] Async RAG Daemon gracefully terminated.', file=sys.stderr)
