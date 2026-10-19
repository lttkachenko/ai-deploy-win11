import json
import traceback
from typing import Any
from fastapi import FastAPI, Request, Response
from mcp.types import JSONRPCMessage

class MCPRouter:
  """Dedicated request routing layer handling raw JSON-RPC protocol interception and proxying."""

  def __init__(self, app: FastAPI, gateway: Any):
    self.app = app
    self.gateway = gateway
    self.runtime_env = gateway.runtime_env
    self.mcp_service = gateway.mcp_service
    self.mcp = gateway.mcp

  def register_routes(self) -> None:
    """Binds production HTTPStreamable endpoints to the FastAPI application instance."""
    self.app.add_api_route("/healthz", self.gateway.health_check, methods = ["GET"])

    @self.app.post("/mcp")
    @self.app.post("/mcp/")
    @self.app.post("/")
    async def master_stateless_gateway(request: Request):
      body_bytes = await request.body()
      payload = json.loads(body_bytes.decode("utf-8")) if body_bytes else {}
      method_call = payload.get("method")
      request_id = payload.get("id", 0) if payload.get("id") is not None else 0

      match method_call:
        case "server/discover":
          return self._handle_discover(request_id)
        case "initialize":
          return self._handle_initialize(request_id)
        case "resources/list":
          return self._handle_resources_list(request_id)
        case "resources/templates/list":
          return self._handle_resources_templates_list(request_id)
        case "resources/read":
          return await self._handle_resources_read(payload, request_id)
        case "tools/list":
          return self._handle_tools_list(request_id)
        case "prompts/list":
          return self._handle_prompts_list(request_id)
        case _:  # Аналог блока 'default' в других языках
          return await self._proxy_to_core_sdk(payload, method_call, request_id)

  def _handle_discover(self, request_id: int) -> Response:
    """Resolves capability transport discovery probes."""
    response_dict = {
      "jsonrpc": "2.0",
      "id": request_id,
      "result": {
        "protocolVersions": ["2024-11-05"],
        "serverInfo": {"name": "ai-dev-mcp-srv", "version": "1.0.0"}
      }
    }
    return self.gateway._build_stateless_response(json.dumps(response_dict))

  def _handle_initialize(self, request_id: int) -> Response:
    """Manages protocol initialization handshake sequences."""
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

    return self.gateway._build_stateless_response(json.dumps(response_dict))

  def _handle_resources_list(self, request_id: int) -> Response:
    """Generates structural folder manifest response directly from runtime schema context."""
    default_folders = ["Artifacts", "Insights", "Roles", "Skills", "User"]
    target_folders = []

    try:
      # Safe type check for cases where routing_manifest might be a list or a dict
      manifest = self.runtime_env.get("routing_manifest", [])
      if isinstance(manifest, dict):
        target_folders = manifest.get("target_folders", default_folders)
      elif isinstance(manifest, list):
        for item in manifest:
          if isinstance(item, dict) and "folder" in item:
            target_folders.append(item["folder"])
          elif isinstance(item, str):
            target_folders.append(item)
    except Exception:
      pass

    if not target_folders:
      target_folders = default_folders

    response_dict = {
      "jsonrpc": "2.0",
      "id": request_id,
      "result": {
        "resources": [
          {"uri": f"obsidian://{folder}", "name": folder, "mimeType": "text/markdown"} for folder in target_folders
        ]
      }
    }

    return self.gateway._build_stateless_response(json.dumps(response_dict, ensure_ascii = False))

  def _handle_resources_templates_list(self, request_id: int) -> Response:
    """Returns dynamic routing masks allowing clients to construct parameterized resource URIs."""
    response_dict = {
      "jsonrpc": "2.0",
      "id": request_id,
      "result": {
        "resourceTemplates": [{
          "uriTemplate": "obsidian://{folder}/{path}",
          "name": "Obsidian Shard Vault Document",
          "description": "Dynamic lookup mask for reconstructing files and reading virtual directory structures.",
          "mimeType": "text/markdown"
        }]
      }
    }

    return self.gateway._build_stateless_response(json.dumps(response_dict, ensure_ascii = False))

  async def _handle_resources_read(self, payload: dict, request_id: int) -> Response:
    """Executes virtual directory reflection or shard file reconstruction queries with deep metrics."""
    params = payload.get("params", {})
    uri = params.get("uri", "obsidian://")
    try:
      result_text = await self.mcp_service.handle_uri_transaction(uri)

      # Deep instrumentation print to see exact structure returned from Qdrant logic
      print("=" * 60, flush = True)
      print(f"[LOG-READ] Intercepted URI request: '{uri}'", flush = True)
      print(f"[LOG-READ] Returned Object Type: {type(result_text)}", flush = True)

      if isinstance(result_text, dict):
        print(f"[LOG-READ] Dict Keys Found: {list(result_text.keys())}", flush = True)
        print(f"[LOG-READ] Full Dict Content: {json.dumps(result_text, ensure_ascii = False, indent = 2)}", flush = True)
      elif isinstance(result_text, list):
        print(f"[LOG-READ] List Length: {len(result_text)}", flush = True)
        if len(result_text) > 0:
          print(f"[LOG-READ] First Element Type: {type(result_text[0])}", flush = True)
          print(f"[LOG-READ] First Element Snippet: {str(result_text[0])[:150]}", flush = True)
      else:
        print(f"[LOG-READ] Raw String Snippet: {str(result_text)[:200]}", flush = True)
      print("=" * 60, flush = True)

      response_dict = {
        "jsonrpc": "2.0",
        "id": request_id,
        "result": {
          "contents": [{"uri": uri, "mimeType": "text/markdown", "text": str(result_text)}]
        }
      }
      return self.gateway._build_stateless_response(json.dumps(response_dict, ensure_ascii = False))
    except Exception as err:
      print(f"[MCP-RESOURCE-ERR] Failed resource transaction for {uri}: {str(err)}", flush = True)
      error_dict = {
        "jsonrpc": "2.0",
        "id": request_id,
        "error": {"code": -32603, "message": f"Service layer transaction crashed: {str(err)}"}
      }

      return self.gateway._build_stateless_response(json.dumps(error_dict, ensure_ascii = False))

  def _handle_tools_list(self, request_id: int) -> Response:
    """Extracts registered tools directly from FastMCP context to bypass uninitialized core handlers."""
    tools_list = []
    mcp_tools = getattr(self.mcp, "_tools", getattr(self.mcp, "tools", {}))
    iterable_tools = mcp_tools.items() if isinstance(mcp_tools, dict) else enumerate(mcp_tools)

    for tool_name, tool_obj in iterable_tools:
      name = getattr(tool_obj, "name", str(tool_name))
      description = getattr(tool_obj, "description", "")
      input_schema = {"type": "object", "properties": {}}

      if hasattr(tool_obj, "input_model") and hasattr(tool_obj.input_model, "model_json_schema"):
        input_schema = tool_obj.input_model.model_json_schema()
      elif hasattr(tool_obj, "parameters"):
        input_schema = getattr(tool_obj, "parameters", input_schema)

      tools_list.append({"name": name, "description": description, "inputSchema": input_schema})

    response_dict = {"jsonrpc": "2.0", "id": request_id, "result": {"tools": tools_list}}

    return self.gateway._build_stateless_response(json.dumps(response_dict, ensure_ascii = False))

  def _handle_prompts_list(self, request_id: int) -> Response:
    """Extracts registered prompts directly from FastMCP context."""
    prompts_list = []
    mcp_prompts = getattr(self.mcp, "_prompts", getattr(self.mcp, "prompts", {}))
    iterable_prompts = mcp_prompts.items() if isinstance(mcp_prompts, dict) else enumerate(mcp_prompts)

    for prompt_name, prompt_obj in iterable_prompts:
      name = getattr(prompt_obj, "name", str(prompt_name))
      description = getattr(prompt_obj, "description", "")
      arguments = []

      if hasattr(prompt_obj, "arguments"):
        for arg in getattr(prompt_obj, "arguments", []):
          arguments.append({
            "name": getattr(arg, "name", ""),
            "description": getattr(arg, "description", ""),
            "required": getattr(arg, "required", False)
          })

      prompts_list.append({"name": name, "description": description, "arguments": arguments})

    response_dict = {"jsonrpc": "2.0", "id": request_id, "result": {"prompts": prompts_list}}

    return self.gateway._build_stateless_response(json.dumps(response_dict, ensure_ascii = False))

  async def _proxy_to_core_sdk(self, payload: dict, method_call: str, request_id: int) -> Response:
    """Forwards remaining standard primitives over to the localized FastMCP execution engine."""
    core_server = getattr(self.mcp, "_mcp_server", getattr(self.mcp, "_server", None))
    if core_server and hasattr(core_server, "handle_request"):
      try:
        if "params" in payload and "_meta" in payload["params"]:
          try:
            payload["params"]["_meta"]["io.modelcontextprotocol/protocolVersion"] = "2024-11-05"
          except Exception:
            pass

        message = JSONRPCMessage.model_validate(payload)
        mcp_response = await core_server.handle_request(message)

        if hasattr(mcp_response, "model_dump_json"):
          res_content = mcp_response.model_dump_json()
        elif hasattr(mcp_response, "json"):
          res_content = mcp_response.json()
        else:
          res_content = json.dumps(mcp_response, ensure_ascii = False)

        return self.gateway._build_stateless_response(res_content)
      except Exception as err:
        print(f"[MCP-CORE-ERR] Core transaction failure on method '{method_call}': {str(err)}", flush = True)
        traceback.print_exc()

        error_payload = {
          "jsonrpc": "2.0",
          "id": request_id,
          "error": {"code": -32603, "message": f"Core execution exception: {str(err)}"}
        }

        return self.gateway._build_stateless_response(json.dumps(error_payload))

    error_payload = {
      "jsonrpc": "2.0",
      "id": request_id,
      "error": {"code": -32601, "message": f"Method '{method_call}' not found or pipeline uninitialized."}
    }

    return self.gateway._build_stateless_response(json.dumps(error_payload))
