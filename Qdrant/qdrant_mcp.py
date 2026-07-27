import os
import sys
import re
import asyncio
from fastmcp import FastMCP
from qdrant_client import AsyncQdrantClient
from qdrant_client.models import Filter, FieldCondition, MatchValue

# Enforce absolute runtime directory injection for absolute stability
current_runtime_dir = os.path.dirname(os.path.abspath(__file__))
if current_runtime_dir not in sys.path:
  sys.path.insert(0, current_runtime_dir)

import libs

# --- Dynamic Configuration Parser Setup (DOS-9 / LocalSystem Compliance) ---
def load_mcp_stack_config() -> dict:
  """Parse centralized yaml matrix by resolving absolute config coordinates dynamically."""
  # Enforce programmatic resolution via injected env vars mapped by NSSM profile wrapper
  ai_config_env = os.environ.get('AI_CONFIG_PATH')

  if ai_config_env and os.path.exists(ai_config_env):
    config_path = ai_config_env
  else:
    # Fallback to absolute parent distribution scaffolding layout paths
    config_path = os.path.abspath(os.path.join(current_runtime_dir, '..', '..', '.ai', 'conf', 'mcp.conf.yml'))
    if not os.path.exists(config_path):
      # --- DOS-9 Fix: Programmatic host user fallback resolution layer ---
      # Safely extract active target username from environment variables injected by NSSM
      target_user = os.environ.get('USERNAME', os.environ.get('USER', 'User'))
      config_path = f'C:\\Users\\{target_user}\\.ai\\conf\\mcp.conf.yml'

  default_config = {
    'port': 8095,
    'qdrant_url': 'http://127.0.0.1:8093',
    'collection_name': 'obsidian_knowledge',
    'api_key': 'dev-srv-key-default'
  }

  if not os.path.exists(config_path):
    print(f'[WARNING] Stack matrix template missing at: {config_path}. Deploying fallbacks.', file=sys.stderr)
    return default_config

  try:
    with open(config_path, 'r', encoding='utf-8') as f:
      content = f.read()

    port_match = re.search(r'fastmcp_sse_port:\s*(\d+)', content)
    url_match = re.search(r'qdrant_rest_port:\s*(\d+)', content)
    collection_match = re.search(r'collection_name:\s*[\'"]?([^\'"\s]+)[\'"]?', content)
    key_match = re.search(r'api_key:\s*[\'"]?([^\'"\s]+)[\'"]?', content)

    detected_port = int(url_match.group(1)) if url_match else 8093
    return {
      'port': int(port_match.group(1)) if port_match else default_config['port'],
      'qdrant_url': f'http://127.0.0.1:{detected_port}',
      'collection_name': collection_match.group(1) if collection_match else default_config['collection_name'],
      'api_key': key_match.group(1) if key_match else default_config['api_key']
    }
  except Exception as e:
    print(f'[ERROR] Failed to extract tokens from mcp.conf.yml: {str(e)}. Deploying fallbacks.', file=sys.stderr)
    return default_config


runtime_env = load_mcp_stack_config()

mcp = FastMCP('Obsidian-RAG-Engine')
QDRANT_URL = runtime_env['qdrant_url']
COLLECTION_NAME = runtime_env['collection_name']
EXPECTED_API_KEY = runtime_env['api_key']

qdrant_client = None


async def initialize_vector_store():
  """Enforce lazy-loading synchronization lock until Qdrant is responsive."""
  global qdrant_client
  await libs.wait_for_qdrant(QDRANT_URL, interval=5)
  qdrant_client = libs.get_qdrant_client(QDRANT_URL)


@mcp.tool()
async def search_knowledge_base(query: str, client_key: str, lang: str = None, limit: int = 3) -> str:
  """
  Search your Obsidian knowledge base for architectural rules, code style templates,
  mocks, fixtures, identity layers, and documentation relevant to the current task.
  Requires a valid client_key to pass security perimeter verification loops.
  """
  global qdrant_client
  if client_key != EXPECTED_API_KEY:
    return '[ERROR] Access Denied: Invalid security perimeter authorization token.'
  if qdrant_client is None:
    return '[ERROR] Context RAG Engine is currently initialization locked. Awaiting vector store connection.'

  try:
    query_vector = await libs.get_embedding(query, is_query=True)
    if not query_vector:
      return '[ERROR] Failed to extract query vector embeddings via shared CPU pipeline.'

    target_lang = lang.lower().strip() if lang else libs.detect_language(query)
    qdrant_filter = Filter(must=[FieldCondition(key='metadata.lang', match=MatchValue(value=target_lang))])

    search_result = await qdrant_client.search(
      collection_name=COLLECTION_NAME,
      query_vector=query_vector,
      query_filter=qdrant_filter,
      limit=limit
    )

    if not search_result:
      return f'No relevant [{target_lang.upper()}] context discovered in knowledge base matching metadata filters.'

    formatted_results = []
    for hit in search_result:
      payload = hit.payload
      text = payload.get('text', '')
      meta = payload.get('metadata', {})
      source = meta.get('source_file', 'Unknown Source')
      score = round(hit.score, 4)
      formatted_results.append(f'--- Context Source: {source} (Similarity Score: {score}) ---\n{text}\n')

    return '\n'.join(formatted_results)
  except Exception as e:
    return f'[ERROR] Failed to query local host vector database node: {str(e)}'


if __name__ == '__main__':
  loop = asyncio.get_event_loop()
  loop.run_until_complete(initialize_vector_store())

  target_port = runtime_env['port']
  print(f'[FastMCP] Initializing SSE context loop interface at 127.0.0.1:{target_port}', file=sys.stderr)
  mcp.run(transport='sse', host='127.0.0.1', port=target_port)
