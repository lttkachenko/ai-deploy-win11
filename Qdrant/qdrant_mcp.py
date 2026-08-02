# .\Qdrant\qdrant_mcp.py - Declarative FastMCP REST-like Gateway Router
# Enforced Quality Matrix: Spaces 2, LF, SingleQuotes, Strictly English Comments
# Single Source of Truth Alignment: Dynamic initialization via native FastMCP Lifespan Hooks

import os
import sys
import asyncio
import contextlib
from fastmcp import FastMCP
from qdrant_client import AsyncQdrantClient

# Inject absolute path coordinates to protect LocalSystem runtime context
current_runtime_dir = os.path.dirname(os.path.abspath(__file__))
if current_runtime_dir not in sys.path:
  sys.path.insert(0, current_runtime_dir)

import mcp_api

def load_mcp_stack_config() -> dict:
  """Parse centralized yaml configuration matrix strictly matching single-source constraints."""
  ai_config_env = os.environ.get('AI_CONFIG_PATH')

  if ai_config_env and os.path.exists(ai_config_env):
    config_path = ai_config_env
  else:
    config_path = os.path.abspath(os.path.join(current_runtime_dir, '..', '..', '.ai', 'conf', 'mcp.conf.yml'))
    if not os.path.exists(config_path):
      target_user = os.environ.get('USERNAME', os.environ.get('USER', 'User'))
      config_path = f'C:\\Users\\{target_user}\\.ai\\conf\\mcp.conf.yml'

  if not os.path.exists(config_path):
    raise FileNotFoundError(f'[FATAL] Centralized stack manifest missing at target destination: {config_path}')

  extracted_config = {}
  current_section = None

  # DOS-12: Section-aware stream tokenizer to strictly isolate dynamic multi-key matrices
  with open(config_path, 'r', encoding='utf-8') as f:
    for line in f:
      clean_line = line.strip()
      if not clean_line or clean_line.startswith('#'):
        continue

      # Track YAML block boundaries contextually
      if clean_line.startswith(('servers:', 'watchers:')):
        current_section = clean_line.split(':', 1)[0].strip()
        continue

      if ':' not in clean_line:
        continue

      key, val = [token.strip().strip("'\"") for token in clean_line.split(':', 1)]

      # Strictly lock server parameters only inside the active 'servers' scope block
      if current_section == 'servers':
        if key == 'port' and val.isdigit():
          extracted_config['port'] = int(val)
        elif key == 'api_key':
          extracted_config['api_key'] = val
        elif key == 'name':
          extracted_config['service_name'] = val

      # Global context tokens or fallback anchors
      if key == 'db':
        extracted_config['collection_name'] = val
      elif key == 'store':
        extracted_config['qdrant_url'] = val

  # Enforce rigorous validation boundary to completely block implicit configuration leaks
  mandatory_tokens = ['port', 'api_key', 'collection_name', 'qdrant_url']
  for token in mandatory_tokens:
    if token not in extracted_config:
      raise KeyError(f'[FATAL] Mandatory layout parameter key "{token}" is missing inside mcp.conf.yml matrix.')

  return extracted_config

# Initialize strict environment specification maps
runtime_env = load_mcp_stack_config()

# Scaffold the context server domain specifying its native asynchronous lifespan container loop
mcp = FastMCP('Obsidian-Vector-API-Gateway')
QDRANT_URL = runtime_env['qdrant_url']
COLLECTION_NAME = runtime_env['collection_name']
EXPECTED_API_KEY = runtime_env['api_key']

qdrant_client = None


# --- DOS-12 Lifespan App Context Hook Integration ---
# This context manager forces FastMCP to allocate client connections inside its active running loop
@mcp.lifespan()
@contextlib.asynccontextmanager
async def mcp_lifespan(server):
  """Establish fluid non-blocking connection maps within the active server event loop framework."""
  global qdrant_client, QDRANT_URL
  print(f'[INIT] Spinning up async client context bound to vector store at: {QDRANT_URL}', file=sys.stderr)

  # Lazy load libs module at runtime boundary to completely bypass NTDLL loader locks
  import libs
  qdrant_client = libs.get_qdrant_client(QDRANT_URL)

  try:
    yield
  finally:
    # Gracefully flush connections on headless daemon teardown boundaries
    print('[SHUTDOWN] Severing active vector store database connection descriptors...', file=sys.stderr)
    if qdrant_client:
      await qdrant_client.close()


@mcp.tool()
async def get_api(client_key: str, uri: str = None) -> dict:
  """Swagger-like discovery root endpoint and sub-path directory hierarchy navigator."""
  global qdrant_client, EXPECTED_API_KEY, COLLECTION_NAME
  if client_key != EXPECTED_API_KEY:
    return {'error': 'Access Denied: Invalid security perimeter authorization token.'}
  if qdrant_client is None:
    return {'error': 'Infrastructure Lock: Awaiting vector store connection context.'}

  return await mcp_api.get_api(qdrant_client, COLLECTION_NAME, uri)


@mcp.tool()
async def get_resource(uri: str, client_key: str) -> dict:
  """REST-like resource ingestion node. Extracts pure markdown blocks matching specific unique URI tokens."""
  global qdrant_client, EXPECTED_API_KEY, COLLECTION_NAME
  if client_key != EXPECTED_API_KEY:
    return {'error': 'Access Denied: Invalid security perimeter authorization token.'}
  if qdrant_client is None:
    return {'error': 'Infrastructure Lock: Awaiting vector store connection context.'}

  return await mcp_api.get_resource(uri, qdrant_client, COLLECTION_NAME)


if __name__ == '__main__':
  import uvicorn
  from fastapi import FastAPI, Request
  from fastapi.responses import JSONResponse

  target_port = runtime_env['port']
  print(f'[FastMCP] Mounting native HTTP REST API engine with Swagger on port {target_port}...', file=sys.stderr)

  # DOS-12: Modern section-aware lifespan configuration loop for FastAPI architecture
  @contextlib.asynccontextmanager
  async def fastapi_lifespan(app: FastAPI):
    print('[BRIDGE] Spawning native FastMCP container loop on isolated channel...', file=sys.stderr)
    # Run native FastMCP on a hidden port 8096, keeping 8000 and 8095 completely safe
    mcp_task = asyncio.create_task(mcp.run_async(transport='sse', host='127.0.0.1', port=8096))

    # Trigger FastMCP's internal lifespan manually to establish client link since we aren't hitting its port directly
    import libs
    global qdrant_client, QDRANT_URL
    qdrant_client = libs.get_qdrant_client(QDRANT_URL)

    try:
      yield
    finally:
      print('[BRIDGE] Termination sequence triggered. Evicting FastMCP run loops...', file=sys.stderr)
      mcp_task.cancel()
      if qdrant_client:
        await qdrant_client.close()

  # Instantiate clean FastAPI application block to expose flat Swagger endpoints
  app = FastAPI(title="Obsidian-Vector-REST-Gateway", version="2.0.0-DOS-12", lifespan=fastapi_lifespan)

  # Create flat REST endpoints for Postman bypassing brittle multi-tier SSE tunnels
  @app.post('/api/get_api')
  async def http_get_api(request: Request):
    payload = await request.json()
    client_key = payload.get('client_key')
    uri = payload.get('uri', None)
    res = await get_api(client_key=client_key, uri=uri)
    return JSONResponse(content=res)

  @app.post('/api/get_resource')
  async def http_get_resource(request: Request):
    payload = await request.json()
    client_key = payload.get('client_key')
    uri = payload.get('uri')
    res = await get_resource(uri=uri, client_key=client_key)
    return JSONResponse(content=res)

  # Run standard enterprise-grade HTTP web runtime server strictly on port 8095
  uvicorn.run(app, host='127.0.0.1', port=target_port, log_level='info')
