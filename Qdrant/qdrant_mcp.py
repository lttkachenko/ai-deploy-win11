import sys
import asyncio
from mcp.server.fastmcp import FastMCP
from qdrant_client import AsyncQdrantClient
from qdrant_client.models import Filter, FieldCondition, MatchText

# Import shared enterprise data components
import libs

# --- Configuration Scaffolding ---
mcp = FastMCP('Obsidian-RAG-Engine')
QDRANT_URL = 'http://127.0.0.1:6333'

# Global reference for late-binding client initialization
qdrant_client = None


async def initialize_vector_store():
  """Enforce lazy-loading synchronization lock until Qdrant is responsive."""
  global qdrant_client
  # Block execution thread safely without crashing the service loop process
  await libs.wait_for_qdrant(QDRANT_URL, interval=5)
  # Safely instantiate connection sequence once socket allocation is cleared
  qdrant_client = libs.get_qdrant_client(QDRANT_URL)


@mcp.tool()
async def search_knowledge_base(query: str, lang: str = None, limit: int = 3) -> str:
  """
  Search your Obsidian knowledge base for architectural rules, code style templates,
  mocks, fixtures, identity layers, and documentation relevant to the current task.
  """
  global qdrant_client
  # Fail-soft guard constraint: reject operations if client bootstrapping is active
  if qdrant_client is None:
    return '[ERROR] Context RAG Engine is currently initialization locked. Awaiting vector store connection.'

  try:
    query_vector = await libs.get_embedding(query, is_query=True)
    if not query_vector:
      return '[ERROR] Failed to extract query vector embeddings via shared CPU pipeline.'

    target_lang = lang.lower().strip() if lang else libs.detect_language(query)
    match_suffix = '-RU' if target_lang == 'ru' else '-EN'

    qdrant_filter = Filter(
      must=[
        FieldCondition(
          key='metadata.source_file',
          match=MatchText(text=match_suffix)
        )
      ]
    )

    search_result = await qdrant_client.search(
      collection_name=libs.COLLECTION_NAME,
      query_vector=query_vector,
      query_filter=qdrant_filter,
      limit=limit
    )

    if not search_result:
      return f'No relevant [{target_lang.upper()}] context found in knowledge base matching filter suffix.'

    formatted_results = []
    for hit in search_result:
      payload = hit.payload
      text = payload.get('text', '')
      meta = payload.get('metadata', {})
      source = meta.get('source_file', 'Unknown Source')
      score = round(hit.score, 4)

      formatted_results.append(
        f'--- Context Source: {source} (Similarity Score: {score}) ---\n{text}\n'
      )

    return '\n'.join(formatted_results)

  except Exception as e:
    return f'[ERROR] Failed to query local host vector database node: {str(e)}'


if __name__ == '__main__':
  # Extract low-level asyncio loop context block from FastMCP infrastructure
  loop = asyncio.get_event_loop()
  # Force execute our late-binding verification thread before opening network sockets
  loop.run_until_complete(initialize_vector_store())

  # Once verification clears, launch the standard SSE HTTP server
  mcp.run(transport='sse', host='127.0.0.1', port=8000)
