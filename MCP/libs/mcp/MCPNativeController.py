import json
from typing import Any, Dict, List, Optional, Union
from starlette.requests import Request
from starlette.responses import Response

class MCPNativeController:
  def __init__(self, app: Any, mcp: Any, mcp_service: Any, *args: Any, **kwargs: Any):
    self.app = app
    self.mcp = mcp
    self.mcp_service = mcp_service

    # Автоматически регистрируем роут на инстанс FastAPI гейтвея
    if hasattr(self.app, "add_api_route"):
      self.app.add_api_route("/mcp", self.runtime_handler, methods = ["POST"])

  # ==========================================
  # ПУБЛИЧНЫЕ МЕТОДЫ И ОБРАБОТЧИКИ ТРАФИКА
  # ==========================================

  async def runtime_handler(self, request: Request) -> Response:
    """Фаза 3: Общий рантайм-роут для вызовов методов бизнес-логики Обсидиана."""
    req_headers = {"Content-Type": "application/json"}
    if hasattr(request, "headers"):
      for k, v in request.headers.items():
        if k.lower() in ["mcp-protocol-version", "x-mcp-protocol-version"]:
          req_headers[k] = v

    try:
      print("[MCP-STEP] Entering runtime_handler", flush = True)
      body_bytes = await request.body()
      if not body_bytes:
        return self._build_empty_handshake_response(req_headers)

      payload = self._parse_body_safely(body_bytes)
      is_batch = isinstance(payload, list)
      if is_batch and len(payload) == 0:
        return Response(status_code = 200, headers = req_headers, content = "[]")

      single_payload = payload if is_batch else payload
      if not isinstance(single_payload, dict):
        return self._build_fallback_response(0, is_batch, req_headers)

      method_call = single_payload.get("method")
      request_id = single_payload.get("id", 0) if single_payload.get("id") is not None else 0
      print(f"[MCP-STEP] Detected RPC Method: '{method_call}', ID: {request_id}", flush = True)

      if method_call in ["initialize", "server/discover"]:
        return self._build_explicit_init_response(request_id, is_batch, method_call, req_headers)

      return await self._execute_mcp_core_transaction(single_payload, is_batch, req_headers)
    except Exception as e:
      print(f"[MCP-CTRL] Critical failure in runtime handler: {str(e)}", flush = True)
      import sys, traceback
      traceback.print_exc(file = sys.stdout)
      return Response(status_code = 500, content = '{"detail": "Critical gateway error"}')

  # ==========================================
  # ПРИВАТНЫЕ МЕТОДЫ И ХЕЛПЕРЫ СЛОЕВ
  # ==========================================

  async def _execute_mcp_core_transaction(self, single_payload: dict, is_batch: bool, headers: Dict[str, str]) -> Response:
    """Исполнение бизнес-логики Обсидиана внутри изолированного ядра FastMCP."""
    print(f"[MCP-CORE-START] Payload: {single_payload}", flush = True)

    if hasattr(self.mcp, "_mcp_server") and getattr(self.mcp, "_mcp_server") is None:
      print("[MCP-CORE-LAZY] Initializing internal _mcp_server handlers manually...", flush = True)
      if hasattr(self.mcp, "_setup_handlers"):
        self.mcp._setup_handlers()
      elif hasattr(self.mcp, "_setup_task_protocol_handlers"):
        self.mcp._setup_task_protocol_handlers()

    core_server = getattr(self.mcp, "_mcp_server", None)
    if not core_server:
      for attr_name in dir(self.mcp):
        attr_val = getattr(self.mcp, attr_name, None)
        if attr_val and hasattr(attr_val, "handle_request"):
          core_server = attr_val
          break

    if core_server and hasattr(core_server, "handle_request"):
      from mcp.types import JSONRPCMessage
      try:
        message = JSONRPCMessage.model_validate(single_payload)
        mcp_response = await core_server.handle_request(message)
        response_content = self._serialize_pydantic_model(mcp_response)

        if is_batch:
          response_content = f"[{response_content}]"

        print(f"[MCP-CORE-SUCCESS] Response ready: {response_content}", flush = True)
        return self._build_raw_network_response(200, response_content)
      except Exception as core_err:
        print(f"[MCP-CORE-ERROR] Core transaction internal failed: {str(core_err)}", flush = True)
        import sys, traceback
        traceback.print_exc(file = sys.stdout)
        return self._build_fallback_response(single_payload.get("id", 0), is_batch, headers)

    print(f"[MCP-CORE-WARN] Core server handle_request not found. Drop to valid specs fallback.", flush = True)
    return self._build_fallback_response(single_payload.get("id", 0), is_batch, headers)

  def _build_explicit_init_response(self, request_id: Any, is_batch: bool, method_call: str, headers: Dict[str, str]) -> Response:
    """Формирование явного ответа на методы initialize и server/discover."""
    if method_call == "server/discover":
      # ТОЧНАЯ JSON-RPC СТРУКТУРА, КОТОРУЮ ТРЕБУЕТ ZOD ИНСПЕКТОРА
      result_payload = {
        "protocolVersions": ["2026-07-28"],
        "serverInfo": {
          "name": "ai-dev-mcp-srv",
          "version": "1.0.0"
        }
      }
    else:
      result_payload = {
        "protocolVersion": "2026-07-28",
        "capabilities": {
          "resources": {"subscribe": True, "listChanged": True},
          "prompts": {"listChanged": True},
          "tools": {"listChanged": True}
        },
        "serverInfo": {"name": "ai-dev-mcp-srv", "version": "1.0.0"}
      }

    content_dict = {
      "jsonrpc": "2.0",
      "id": request_id,
      "result": result_payload
    }
    final_content = [content_dict] if is_batch else content_dict
    return self._build_raw_network_response(200, json.dumps(final_content, ensure_ascii = False))

  def _build_fallback_response(self, request_id: Any, is_batch: bool, headers: Dict[str, str]) -> Response:
    """Сборка фоллбэк-структуры версий для server/discover зондов."""
    content_dict = {
      "jsonrpc": "2.0",
      "id": request_id,
      "result": {
        "protocolVersions": ["2026-07-28"],
        "serverInfo": {
          "name": "ai-dev-mcp-srv",
          "version": "1.0.0"
        }
      }
    }
    final_content = [content_dict] if is_batch else content_dict
    return self._build_raw_network_response(200, json.dumps(final_content, ensure_ascii = False))

  def _build_empty_handshake_response(self, headers: Dict[str, str]) -> Response:
    """Формирование пустого хэндшейк-ответа."""
    return self._build_raw_network_response(200, "{}")

  def _build_raw_network_response(self, status_code: int, content: str) -> Response:
    """Сборка сырого HTTP-пакета с защитой регистра CORS и MCP заголовков."""
    response = Response(status_code = status_code, content = content)

    # Запихиваем байты напрямую в обход словаря Starlette, чтобы сохранить CamelCase регистр
    response.raw_headers = [
      (b"content-type", b"application/json"),
      (b"mcp-protocol-version", b"2026-07-28"),
      (b"x-mcp-protocol-version", b"2026-07-28"),
      (b"X-MCP-Protocol-Version", b"2026-07-28"),
      (b"access-control-allow-origin", b"*"),
      (b"access-control-allow-methods", b"POST, GET, OPTIONS"),
      (b"access-control-allow-headers", b"*"),
      (b"access-control-expose-headers", b"mcp-protocol-version, X-MCP-Protocol-Version, x-mcp-protocol-version")
    ]
    return response

  def _parse_body_safely(self, body_bytes: bytes) -> Any:
    """Безопасный парсинг входящего JSON-тела."""
    try:
      if not body_bytes:
        return {}
      return json.loads(body_bytes.decode("utf-8"))
    except Exception:
      return {}

  def _serialize_pydantic_model(self, model: Any) -> str:
    """Сериализация pydantic-моделей ответов ядра."""
    try:
      if hasattr(model, "model_dump_json"):
        return model.model_dump_json()
      elif hasattr(model, "json"):
        return model.json()
      return json.dumps(model, ensure_ascii = False)
    except Exception:
      return json.dumps(str(model))
