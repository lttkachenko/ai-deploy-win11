# /MCP/libs/mcp/MCPGateway.py
import json
import sys
from contextlib import asynccontextmanager
from typing import Dict, Any

import uvicorn
from fastapi import FastAPI, Request
from fastapi.responses import Response, JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from fastmcp import FastMCP

from libs.store import StoreType
from .IMCPGateway import IMCPGateway
from .MCPService import MCPService
from .MCPAuthMiddleware import MCPAuthMiddleware


@asynccontextmanager
async def gateway_lifespan(app: FastAPI):
  """Глобальный менеджер жизненного цикла приложения без вложенностей."""
  gateway_instance = app.state.gateway
  await gateway_instance.on_startup()
  yield
  await gateway_instance.on_shutdown()


class MCPGateway(IMCPGateway):
  """Gateway server management class encapsulating FastAPI router and FastMCP contexts."""

  def __init__(self, runtime_env: Dict[str, Any]):
    self.runtime_env = runtime_env
    self._parse_config(runtime_env)

    self.mcp = FastMCP("Obsidian-Vector-Resource-Gateway")
    self.mcp_service = MCPService(raw_config = self.runtime_env, store_type = StoreType.QDRANT)

    self.app = FastAPI(title = "Explicit Production Gateway", lifespan = gateway_lifespan)
    self.app.state.gateway = self

    # Регистрируем инфраструктурные слои
    self._register_http_routes()
    self._register_mcp_routes()
    self._setup_security()

  # ==========================================
  # РЕАЛИЗАЦИЯ МЕТОДОВ ИНТЕРФЕЙСА IMCPGateway
  # ==========================================

  async def on_startup(self) -> None:
    print("[INIT] Securing connector session to vector store cluster...", flush = True)
    await self.mcp_service.initialize()

    # Принудительно будим обработчики ядра FastMCP на старте
    if hasattr(self.mcp, "_setup_handlers"):
      self.mcp._setup_handlers()
    elif hasattr(self.mcp, "_setup_task_protocol_handlers"):
      self.mcp._setup_task_protocol_handlers()

  async def on_shutdown(self) -> None:
    print("[SHUTDOWN] Breaking active database connection handles...", flush = True)
    if self.mcp_service and self.mcp_service._store_client:
      await self.mcp_service._store_client.close()

  async def health_check(self) -> JSONResponse:
    """HTTP GET endpoint for infrastructure health verification."""
    result = {"status": "healthy", "qdrant": {"connected": False, "details": "Uninitialized"}}
    if self.mcp_service and self.mcp_service._store_client and self.mcp_service._store_client.client:
      try:
        await self.mcp_service._store_client.client.get_collections()
        result["qdrant"]["connected"] = True
        result["qdrant"]["details"] = "Connected and responsive"
        prompt_content = await self.mcp_service.handle_uri_transaction("obsidian://Prompts/system-prompt")
        if not prompt_content:
          result["status"] = "warning"
      except Exception as e:
        result["status"] = "error"
        result["qdrant"]["details"] = str(e)
    return JSONResponse(content = result)

  # ==========================================
  # ПУБЛИЧНЫЕ МЕТОДЫ И КЛИЕНТСКИЙ ЗАПУСК
  # ==========================================

  async def dynamic_resource_router(self, folder: str, path: str) -> str:
    full_uri = f"obsidian://{folder}/{path}"
    return await self.mcp_service.handle_uri_transaction(full_uri)

  async def dynamic_prompt_router(self, prompt_name: str) -> str:
    full_uri = f"obsidian://Prompts/{prompt_name}"
    return await self.mcp_service.handle_uri_transaction(full_uri)

  def start(self) -> None:
    """Launches the uvicorn ASGI server hosting the HTTPStreamable transport."""
    print(f"[UVICORN] Launching explicit HTTP gateway on {self.host_bind}:{self.fmcp_target_port}...", flush = True)
    sys.stdout.flush()
    uvicorn.run(self.app, host = self.host_bind, port = self.fmcp_target_port, log_level = "info")

  # ==========================================
  # ПРИВАТНЫЕ МЕТОДЫ И НАСТРОЙКА СЛОЕВ
  # ==========================================

  def _register_http_routes(self) -> None:
    self.app.add_api_route("/healthz", self.health_check, methods = ["GET"])

    # СТАБИЛЬНЫЙ REST-РОУТ С ПОДДЕРЖКОЙ КЛАССИЧЕСКОЙ ВЕРСИИ ПРОТОКОЛА
    @self.app.post("/mcp")
    @self.app.post("/mcp/")
    @self.app.post("/")
    async def mcp_modern_stateless_gateway(request: Request):
      body_bytes = await request.body()
      payload = json.loads(body_bytes.decode("utf-8")) if body_bytes else {}

      method_call = payload.get("method")
      request_id = payload.get("id", 0) if payload.get("id") is not None else 0

      # 1. Перехватываем транспортный зонд и отдаем совместимую версию
      if method_call == "server/discover":
        response_dict = {
          "jsonrpc": "2.0",
          "id": request_id,
          "result": {
            "protocolVersions": ["2024-11-05"],
            "serverInfo": {"name": "ai-dev-mcp-srv", "version": "1.0.0"}
          }
        }
        return self._build_stateless_response(json.dumps(response_dict))

      if method_call == "initialize":
        response_dict = {
          "jsonrpc": "2.0",
          "id": request_id,
          "result": {
            "protocolVersion": "2024-11-05",
            "capabilities": {
              "resources": {"subscribe": True, "listChanged": True},
              "prompts": {"listChanged": True},
              "tools": {"listChanged": True}
            },
            "serverInfo": {"name": "ai-dev-mcp-srv", "version": "1.0.0"}
          }
        }
        return self._build_stateless_response(json.dumps(response_dict))

      # 2. Все остальные бизнес-вызовы (tools/list, prompts/list) шлем в ядро
      core_server = getattr(self.mcp, "_mcp_server", getattr(self.mcp, "_server", None))
      if core_server and hasattr(core_server, "handle_request"):
        from mcp.types import JSONRPCMessage
        try:
          # Временно подменяем версию в метаданных запроса, чтобы ядро SDK mcp не ругалось
          if "params" in payload and "_meta" in payload["params"]:
            payload["params"]["_meta"]["io.modelcontextprotocol/protocolVersion"] = "2024-11-05"

          message = JSONRPCMessage.model_validate(payload)
          mcp_response = await core_server.handle_request(message)

          if hasattr(mcp_response, "model_dump_json"):
            res_content = mcp_response.model_dump_json()
          elif hasattr(mcp_response, "json"):
            res_content = mcp_response.json()
          else:
            res_content = json.dumps(mcp_response, ensure_ascii = False)

          return self._build_stateless_response(res_content)
        except Exception as err:
          print(f"[MCP-CORE-ERR] Core transaction failed: {str(err)}", flush = True)

      fallback_dict = {"jsonrpc": "2.0", "id": request_id, "result": {"protocolVersions": ["2024-11-05"]}}
      return self._build_stateless_response(json.dumps(fallback_dict))

  def _build_stateless_response(self, content: str) -> Response:
    """Сборка HTTP-ответа с принудительными CORS-заголовками версии 2024-11-05."""
    res = Response(status_code = 200, content = content)
    res.headers["content-type"] = "application/json"
    res.headers["mcp-protocol-version"] = "2024-11-05"
    res.headers["x-mcp-protocol-version"] = "2024-11-05"
    res.headers["X-MCP-Protocol-Version"] = "2024-11-05"
    res.headers["Access-Control-Allow-Origin"] = "*"
    res.headers["Access-Control-Allow-Methods"] = "POST, GET, OPTIONS"
    res.headers["Access-Control-Allow-Headers"] = "*"
    res.headers["Access-Control-Expose-Headers"] = "mcp-protocol-version, X-MCP-Protocol-Version, x-mcp-protocol-version"
    return res

  def _parse_config(self, raw_config: Dict[str, Any]) -> None:
    if not raw_config:
      raise ValueError("[MCP-GATEWAY] Critical error: Server configuration matrix is null or empty.")
    target_port = raw_config.get("port") or raw_config.get("fmcp_port")
    if not target_port:
      raise ValueError("[MCP-GATEWAY] Critical error: Required parameter 'port' missing.")
    self.fmcp_target_port = int(target_port)
    raw_host = raw_config.get("host", "127.0.0.1")
    clean_host_str = str(raw_host).replace("http://", "").replace("https://", "")
    self.host_bind = clean_host_str.split(":") if ":" in clean_host_str else clean_host_str
    print(f"[MCP-GATEWAY] Configuration validated. Service port bound to: {self.fmcp_target_port} on host: {self.host_bind}", flush = True)

  def _setup_security(self) -> None:
    token = self.runtime_env.get("api_key", "ai-dev-mcp-srv-key-default")
    self.app.add_middleware(MCPAuthMiddleware, target_token = token)
    self.app.add_middleware(
      CORSMiddleware,
      allow_origins = ["*"],
      allow_credentials = True,
      allow_methods = ["*"],
      allow_headers = ["*"],
      expose_headers = ["mcp-protocol-version", "X-MCP-Protocol-Version"]
    )

  def _register_mcp_routes(self) -> None:
    service = self.mcp_service

    @self.mcp.resource("obsidian://{folder}/{path}")
    async def dynamic_resource_router(folder: str, path: str) -> str:
      full_uri = f"obsidian://{folder}/{path}"
      result = await service.handle_uri_transaction(full_uri)
      return json.dumps(result, ensure_ascii = False, indent = 2) if isinstance(result, dict) else str(result)

    @self.mcp.prompt("obsidian://Prompts/{prompt_name}")
    async def dynamic_prompt_router(prompt_name: str) -> str:
      full_uri = f"obsidian://Prompts/{prompt_name}"
      result = await service.handle_uri_transaction(full_uri)
      return str(result)
