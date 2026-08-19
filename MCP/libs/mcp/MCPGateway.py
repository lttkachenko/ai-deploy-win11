# /MCP/libs/mcp/MCPGateway.py
import json
import sys
from contextlib import asynccontextmanager
from typing import Dict, Any

import uvicorn
from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from fastmcp import FastMCP

from libs.store import StoreType
from .IMCPGateway import IMCPGateway
from .MCPService import MCPService
from .MCPAuthMiddleware import MCPAuthMiddleware
from .MCPNativeController import MCPNativeController


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

    # ИНИЦИАЛИЗИРУЕМ ВЫДЕЛЕННЫЙ ДЕКЛАРАТИВНЫЙ КОНТРОЛЛЕР РОУТОВ
    self.mcp_controller = MCPNativeController(
      app = self.app,
      mcp = self.mcp,
      mcp_service = self.mcp_service
    )

    # Регистрируем оставшиеся инфраструктурные слои
    self._register_http_routes()
    self._register_mcp_routes()
    self._setup_security()

  # ==========================================
  # РЕАЛИЗАЦИЯ МЕТОДОВ ИНТЕРФЕЙСА IMCPGateway
  # ==========================================

  async def on_startup(self) -> None:
    print("[INIT] Securing connector session to vector store cluster...", flush=True)
    await self.mcp_service.initialize()
    if hasattr(self.mcp, "_server") and hasattr(self.mcp._server, "startup"):
      await self.mcp._server.startup()

  async def on_shutdown(self) -> None:
    print("[SHUTDOWN] Breaking active database connection handles...", flush=True)
    if self.mcp_service and self.mcp_service._store_client:
      await self.mcp_service._store_client.close()
    if hasattr(self.mcp, "_server") and hasattr(self.mcp._server, "shutdown"):
      await self.mcp._server.shutdown()

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
    print(f"[UVICORN] Launching explicit HTTP gateway on {self.host_bind}:{self.fmcp_target_port}...", flush=True)
    sys.stdout.flush()

    uvicorn.run(self.app, host = self.host_bind, port = self.fmcp_target_port, log_level = "info")

  # ==========================================
  # ПРИВАТНЫЕ МЕТОДЫ И НАСТРОЙКА СЛОЕВ
  # ==========================================

  def _parse_config(self, raw_config: Dict[str, Any]) -> None:
    if not raw_config:
      raise ValueError("[MCP-GATEWAY] Critical error: Server configuration matrix is null or empty.")

    target_port = raw_config.get("port") or raw_config.get("fmcp_port")
    if not target_port:
      raise ValueError("[MCP-GATEWAY] Critical error: Required parameter 'port' missing.")
    self.fmcp_target_port = int(target_port)

    raw_host = raw_config.get("host", "127.0.0.1")
    if isinstance(raw_host, list):
      raw_host = raw_host if raw_host else "127.0.0.1"

    clean_host_str = str(raw_host).replace("http://", "").replace("https://", "")

    if ":" in clean_host_str:
      self.host_bind = clean_host_str.split(":")
    else:
      self.host_bind = clean_host_str

    print(f"[MCP-GATEWAY] Configuration validated. Service port bound to: {self.fmcp_target_port} on host: {self.host_bind}", flush=True)

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

  def _register_http_routes(self) -> None:
    self.app.add_api_route("/healthz", self.health_check, methods = ["GET"])

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
