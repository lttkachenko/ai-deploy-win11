import os
import sys
import asyncio
import argparse
import httpx
from watchfiles import awatch, Change
from qdrant_client import AsyncQdrantClient
from qdrant_client.models import VectorParams, Distance
from libs import wait_for_qdrant, index_file

async def main():
  parser = argparse.ArgumentParser(description='Gheimher Multi-Vault Automated Async RAG Watcher')
  parser.add_argument('--vault', type=str, required=True, help='Absolute path to target Obsidian vault')
  parser.add_argument('--collection', type=str, required=True, help='Target Qdrant collection space')
  parser.add_argument('--port', type=int, default=6333, help='Qdrant storage endpoint port')
  parser.add_argument('--ai-url', type=str, default='http://127.0.0.1:11434', help='Inference engine base URL')
  args = parser.parse_args()

  VAULT_PATH = os.path.abspath(args.vault)
  COLLECTION_NAME = args.collection
  QDRANT_PORT = args.port
  QDRANT_URL = f'http://127.0.0.1:{QDRANT_PORT}'
  AI_ENGINE_URL = args.ai_url
  EMBED_MODEL = 'nomic-embed-text'

  if not os.path.exists(VAULT_PATH):
    print(f'[CRITICAL] Vault path missing: {VAULT_PATH}', file=sys.stderr)
    sys.exit(1)

  # Await active storage lifecycle state asynchronously
  await wait_for_qdrant(QDRANT_URL, interval=15)
  qdrant_client = AsyncQdrantClient(url=QDRANT_URL)

  try:
    await qdrant_client.get_collection(COLLECTION_NAME)
  except Exception:
    await qdrant_client.create_collection(
      collection_name=COLLECTION_NAME,
      vectors_config=VectorParams(size=768, distance=Distance.COSINE),
    )

  # Normalize endpoint layout for OpenAI compliance if targeting LM Studio
  handler_ai_endpoint = AI_ENGINE_URL
  if ':1234' in AI_ENGINE_URL and not AI_ENGINE_URL.endswith('/v1'):
    handler_ai_endpoint = f'{AI_ENGINE_URL}/v1'

  print(f">>> Async Watcher active. Target: '{COLLECTION_NAME}' -> Vault: '{VAULT_PATH}'")

  # Continuous non-blocking file auditing loop leveraging rust-backed 'watchfiles' engine
  async with httpx.AsyncClient() as async_client:
    async for changes in awatch(VAULT_PATH):
      for change_type, file_path in changes:
        # We handle added and modified events seamlessly, ignoring hard deletes for cache safety
        if change_type in (Change.add, Change.modify):
          # Fire independent async indexing task without clogging the file system listener loop
          asyncio.create_task(
            index_file(
              file_path=file_path,
              vault_path=VAULT_PATH,
              collection_name=COLLECTION_NAME,
              qdrant_client=qdrant_client,
              async_client=async_client,
              ai_engine_url=handler_ai_endpoint,
              embed_model=EMBED_MODEL
            )
          )

if __name__ == '__main__':
  try:
    asyncio.run(main())
  except KeyboardInterrupt:
    print('\n>>> Async Watcher daemon terminated by user interrupt.', file=sys.stderr)
