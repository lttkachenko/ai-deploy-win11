import sys
import asyncio
import argparse
import httpx
from mcp.server.models import InitializationOptions
from mcp.server import Notification, Server
import mcp.types as types
from libs import get_embedding

# --- Parse Target Collection Allocation ---
parser = argparse.ArgumentParser(description='Gheimher Automated Async MCP Qdrant Bridge')
parser.add_argument(
  '--collection',
  type=str,
  default='db-dev',
  help='Target Qdrant collection to query (e.g., db-dev, db-hobby)'
)
args, unknown = parser.parse_known_args()
sys.argv = [sys.argv] + unknown

TARGET_COLLECTION = args.collection

# --- Configuration Constants ---
QDRANT_URL = 'http://win-host:6333'
AI_ENGINE_URL = 'http://win-host:11434'
EMBED_MODEL = 'nomic-embed-text'

# Initialize low-level async MCP server node
server = Server(f'qdrant-rag-{TARGET_COLLECTION}')

@server.list_tools()
async def handle_list_tools() -> list[types.Tool]:
  '''Advertises operational tool matrix to connected MCP client boundaries.'''
  return [
    types.Tool(
      name='search_knowledge_base',
      description='Search the local structural knowledge base collection for relevant contexts and code blocks.',
      inputSchema={
        'type': 'object',
        'properties': {
          'query': {'type': 'string', 'description': 'The search query string'},
          'limit': {'type': 'integer', 'description': 'Max context chunks to pull', 'default': 5}
        },
        'required': ['query']
      }
    ),
    types.Tool(
      name='hydrate_project_context',
      description='Dynamically fetch high-level system roles, developer playbooks, and architectural guidelines from the RAG store based on extracted identity name token.',
      inputSchema={
        'type': 'object',
        'properties': {
          'context_key': {'type': 'string', 'description': 'Target blueprint identity name or persona token extracted from user query'}
        },
        'required': ['context_key']
      }
    )
  ]

@server.call_tool()
async def handle_call_tool(name: str, arguments: dict | None) -> list[types.TextContent]:
  '''Processes atomic tool call instructions asynchronously without blocking the loop.'''
  if name not in ['search_knowledge_base', 'hydrate_project_context']:
    raise ValueError(f'Unsupported tool invocation request: {name}')

  if not arguments:
    return [types.TextContent(type='text', text='Error: Missing required execution parameters.')]

  async with httpx.AsyncClient() as client:
    # --- Context Hydration Execution Branch ---
    if name == 'hydrate_project_context':
      context_key = arguments['context_key'].lower().strip()

      # Abstract structural query construction targeting dynamic identity vectors
      search_query = f'identity setup operational profile playbook engineering guidelines for persona name: {context_key}'

      vector = await get_embedding(client, search_query, AI_ENGINE_URL, EMBED_MODEL)
      if not vector:
        return [types.TextContent(type='text', text='Error: Unable to generate hydration vector coefficients.')]

      search_endpoint = f'{QDRANT_URL}/collections/{TARGET_COLLECTION}/points/search'
      payload = {'vector': vector, 'limit': 2, 'with_payload': True}

      try:
        res = await client.post(search_endpoint, json=payload, timeout=5.0)
        res.raise_for_status()
        results = res.json().get('result', [])

        if not results:
          return [types.TextContent(type='text', text=f"Hydration failed. Operational playbook asset not found inside vector storage for identity token: '{context_key}'.")]

        formatted_system_blocks = []
        for match in results:
          data = match.get('payload', {})
          text = data.get('text', '')
          source = data.get('metadata', {}).get('source_file', 'Unknown Origin')
          formatted_system_blocks.append(f'### IDENTITY INJECTED: {context_key.upper()} (Source: {source}) ###\n{text}')

        return [types.TextContent(type='text', text='\n\n'.join(formatted_system_blocks))]
      except Exception as e:
        return [types.TextContent(type='text', text=f'CRITICAL: Hydration pipeline connection collapsed. Trace: {str(e)}')]

    # --- Standard Semantic Search Execution Branch ---
    if name == 'search_knowledge_base':
      query = arguments['query']
      limit = arguments.get('limit', 5)

      vector = await get_embedding(client, query, AI_ENGINE_URL, EMBED_MODEL)
      if not vector:
        return [types.TextContent(type='text', text='Error: Unable to generate query vector coefficients.')]

      search_endpoint = f'{QDRANT_URL}/collections/{TARGET_COLLECTION}/points/search'
      payload = {'vector': vector, 'limit': limit, 'with_payload': True}

      try:
        res = await client.post(search_endpoint, json=payload, timeout=5.0)
        res.raise_for_status()
        results = res.json().get('result', [])

        if not results:
          return [types.TextContent(type='text', text=f"No relevant context blocks inside target collection: '{TARGET_COLLECTION}'.")]

        formatted_chunks = []
        for match in results:
          score = match.get('score', 0.0)
          data = match.get('payload', {})
          text = data.get('text', '[Empty Payload]')
          metadata = data.get('metadata', {})
          source = metadata.get('source_file', 'Unknown Origin')

          formatted_chunks.append(
            f"--- CONTEXT BLOCK (Source: {source} | Cosine Match Score: {score:.4f}) ---\n{text}\n"
          )

        return [types.TextContent(type='text', text='\n'.join(formatted_chunks))]
      except Exception as e:
        return [types.TextContent(type='text', text=f'CRITICAL: Vector engine query collapsed. Trace: {str(e)}')]

async def main():
  '''Spawns continuous non-blocking stdio transport channel layer for the MCP protocol.'''
  import mcp.server.stdio
  async with mcp.server.stdio.stdio_server() as (read_stream, write_stream):
    await server.run(
      read_stream,
      write_stream,
      InitializationOptions(
        server_name=server.name,
        server_version='2.2.0',
        capabilities=server.get_capabilities(
          notification_options=Notification(),
          experimental_capabilities={}
        )
      )
    )

if __name__ == '__main__':
  print(f">>> Launching Async Universal MCP Gateway targeting Qdrant Context: [{TARGET_COLLECTION}]", file=sys.stderr)
  asyncio.run(main())
