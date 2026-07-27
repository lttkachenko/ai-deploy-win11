import os
import re
import sys
import asyncio
from watchfiles import awatch
from qdrant_client.models import Distance, VectorParams

current_runtime_dir = os.path.dirname(os.path.abspath(__file__))
if current_runtime_dir not in sys.path:
  sys.path.insert(0, current_runtime_dir)

import libs

def load_mcp_stack_config() -> dict:
  """Parse centralized yaml context deployment schema to decouple infrastructure parameters."""
  ai_config_env = os.environ.get('AI_CONFIG_PATH')
  if ai_config_env and os.path.exists(ai_config_env):
    config_path = ai_config_env
  else:
    config_path = os.path.abspath(os.path.join(current_runtime_dir, '..', '..', '.ai', 'conf', 'mcp.conf.yml'))
    if not os.path.exists(config_path):
      config_path = r'C:\Users\gadeshi\.ai\conf\mcp.conf.yml'

  default_config = {
    'qdrant_url': 'http://127.0.0.1:8093',
    'collection_name': 'obsidian_knowledge',
    'vault_path': 'D:\\Obsidian\\Vaults\\v-dev'
  }

  if not os.path.exists(config_path):
    print(f'[WARNING] Stack configuration matrix missing at: {config_path}. Using safe fallbacks.', file=sys.stderr)
    return default_config

  try:
    with open(config_path, 'r', encoding='utf-8') as f:
      content = f.read()

    url_match = re.search(r'qdrant_rest_port:\s*(\d+)', content)
    collection_match = re.search(r'collection_name:\s*[\'"]?([^\'"\s]+)[\'"]?', content)
    vault_match = re.search(r'vault_path:\s*[\'"]?([^\''"\r\n]+)[\'"]?', content)

    detected_port = int(url_match.group(1)) if url_match else 8093
    return {
      'qdrant_url': f'http://127.0.0.1:{detected_port}',
      'collection_name': collection_match.group(1) if collection_match else default_config['collection_name'],
      'vault_path': vault_match.group(1) if vault_match else default_config['vault_path']
    }
  except Exception as e:
    print(f'[ERROR] Failed to extract tokens from mcp.conf.yml for watcher: {str(e)}. Using fallbacks.', file=sys.stderr)
    return default_config


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
