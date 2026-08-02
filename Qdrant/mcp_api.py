# .\Qdrant\mcp_api.py - Unified Vector REST-Gateway & Dynamic Swagger Router
# Style Enforced: Spaces 2, LF, SingleQuotes, Strict Quality Control
# Single Source of Truth Alignment: Isolated from filesystem disk boundaries

import os
import sys
import uvicorn
from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse
from qdrant_client import AsyncQdrantClient
from qdrant_client.models import Filter, FieldCondition, MatchValue

# Ensure current module context is visible to the interpreter
current_runtime_dir = os.path.dirname(os.path.abspath(__file__))
if current_runtime_dir not in sys.path:
  sys.path.insert(0, current_runtime_dir)

async def resolve_virtual_directory(qdrant_client: AsyncQdrantClient, collection_name: str, target_uri: str) -> dict:
  """Internal aggregated node scanner. Compiles virtual layout matrices via Zero-Text Overhead."""
  try:
    if not target_uri:
      folder_filter = None
    else:
      folder_filter = Filter(must=[FieldCondition(key='metadata.parent_path', match=MatchValue(value=target_uri))])

    # DOS-12 Hardware Optimization: Whitelist metadata execution vectors only
    response, _ = await qdrant_client.scroll(
      collection_name=collection_name,
      scroll_filter=folder_filter,
      limit=500,
      with_payload=['metadata.uri_path', 'metadata.parent_path'],
      with_vectors=False
    )

    # Base structural envelope matrix
    dir_matrix = {
      'mcp_gateway': 'Obsidian-Qdrant-Bridge',
      'version': '3.0.0-DOS-12',
      'node_type': 'VIRTUAL_DIRECTORY_BRANCH',
      'current_virtual_path': target_uri if target_uri else '/',
      'status': 'ACTIVE_NODE' if response else 'EMPTY_NODE'
    }

    discovered_sub_folders = set()
    discovered_assets = set()

    for hit in response:
      meta = hit.payload.get('metadata', {})
      asset_uri = meta.get('uri_path', '').strip('/')
      if not asset_uri:
        continue

      if not target_uri:
        if '/' in asset_uri:
          discovered_sub_folders.add(asset_uri.split('/')[0])
        else:
          discovered_assets.add(asset_uri)
      else:
        if asset_uri.startswith(target_uri + '/'):
          offset = len(target_uri) + 1
          relative_part = asset_uri[offset:]
          if '/' in relative_part:
            next_folder_name = relative_part.split('/')[0]
            discovered_sub_folders.add(f'{target_uri}/{next_folder_name}')
          else:
            discovered_assets.add(asset_uri)

    dir_matrix['sub_directories'] = sorted(list(discovered_sub_folders))
    dir_matrix['available_resources'] = sorted(list(discovered_assets))
    return dir_matrix

  except Exception as e:
    return {'error': f'Internal vector infrastructure directory parsing failure: {str(e)}'}


async def handle_unified_rest_transaction(qdrant_client: AsyncQdrantClient, collection_name: str, uri: str = None) -> dict:
  """
  Unified REST Ingestion Gateway Core Engine.
  Executes precise document chunk extraction, falling back to directory tree mapping if node is missing.
  """
  sanitized_uri = uri.strip().strip('/') if uri else ''

  # DOS-12: Root-level bypass gate - instantly route to tree discovery matrix if uri is completely empty
  if not sanitized_uri:
    return await resolve_virtual_directory(qdrant_client, collection_name, target_uri='')

  try:
    # 1. ATOMIC EXACT-MATCH ROUNDTRIP (Precise file shot)
    resource_filter = Filter(must=[FieldCondition(key='metadata.uri_path', match=MatchValue(value=sanitized_uri))])
    response, _ = await qdrant_client.scroll(
      collection_name=collection_name,
      scroll_filter=resource_filter,
      limit=50,
      with_payload=True, # Fetch text chunks natively only on real documents
      with_vectors=False
    )

    # 2. SE-DETERMINISTIC SMART FALLBACK GATEWAY (Branch/Directory escalation)
    if not response:
      print(f'[ROUTER] Target path "{sanitized_uri}" not a file node. Escalating to folder tree parser.', file=sys.stderr)
      return await resolve_virtual_directory(qdrant_client, collection_name, target_uri=sanitized_uri)

    # 3. COMPILE TEXT PACKETS (Document compiler block)
    sorted_chunks = sorted(response, key=lambda x: x.id)
    full_text_blocks = [chunk.payload.get('text', '') for chunk in sorted_chunks]

    source_file_name = 'Unknown'
    if sorted_chunks:
      source_file_name = sorted_chunks[0].payload.get('metadata', {}).get('source_file', 'Unknown')

    return {
      'mcp_gateway': 'Obsidian-Qdrant-Bridge',
      'version': '3.0.0-DOS-12',
      'node_type': 'TRANSACTIONAL_DOCUMENT_CONTENT',
      'status': 'SUCCESS',
      'uri_path': sanitized_uri,
      'source_file_origin': source_file_name,
      'content': '\n\n'.join(full_text_blocks)
    }

  except Exception as e:
    print(f'[ERROR] Unified transactional route crashed for URI {sanitized_uri}: {str(e)}', file=sys.stderr)
    return {'error': f'Failed to parse operational unified node routing: {str(e)}'}


# --- DOS-12: Enterprise REST-API Gateway Server Layout ---
app = FastAPI(title="Obsidian-Vector-REST-Gateway", version="3.0.0-DOS-12")
app_client = None
cfg = None

@app.on_event('startup')
async def initialize_rest_context():
  global app_client, cfg
  import qdrant_mcp
  import libs
  cfg = qdrant_mcp.load_mcp_stack_config()
  app_client = libs.get_qdrant_client(cfg['qdrant_url'])

# DOS-12: Clean flat REST-endpoint bound strictly to the app root space
@app.post('/')
async def unified_rest_api_endpoint(request: Request):
  global app_client, cfg
  payload = await request.json()

  # Rigorous perimeter security firewall validation
  if payload.get('client_key') != cfg['api_key']:
    return JSONResponse(status_code=401, content={'error': 'Access Denied: Security token mismatch.'})

  uri_target = payload.get('uri', None)
  res = await handle_unified_rest_transaction(app_client, cfg['collection_name'], uri_target)
  return JSONResponse(content=res)

if __name__ == '__main__':
  import qdrant_mcp
  local_cfg = qdrant_mcp.load_mcp_stack_config()
  uvicorn.run(app, host='127.0.0.1', port=local_cfg['port'], log_level='info')
