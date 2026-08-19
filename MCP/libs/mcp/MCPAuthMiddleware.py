# /MCP/libs/mcp/MCPAuthMiddleware.py
import json
from fastapi import Request
from fastapi.responses import JSONResponse
from starlette.middleware.base import BaseHTTPMiddleware


class MCPAuthMiddleware(BaseHTTPMiddleware):
  """Explicit enterprise-grade token validation middleware layer with robust CORS bypass."""

  def __init__(self, app, target_token: str):
    super().__init__(app)
    self.target_token = target_token

  async def dispatch(self, request: Request, call_next):
    # УБРАЛИ ХАК СО СЛЭШЕМ, ЧТОБЫ НЕ ЛОМАТЬ СЕТЕВОЙ СТЕК STARLETTE
    if request.url.path in ["/healthz", "/healthz/"]:
      return await call_next(request)

    if request.url.path in ["/mcp", "/mcp/"]:
      return await call_next(request)

    if request.method == "OPTIONS":
      return await call_next(request)

    auth_header = request.headers.get("Authorization")
    custom_header = request.headers.get("X-Enterprise-Token")

    incoming_token = None
    if custom_header:
      incoming_token = custom_header.strip()
    elif auth_header:
      incoming_token = auth_header.replace("Bearer ", "").strip()

    if not incoming_token or incoming_token != self.target_token:
      client_ip = request.client.host if request.client else "Unknown"
      print(f"[AUTH-GATE] Unauthorized access attempt blocked from: {client_ip}", flush=True)
      return JSONResponse(
        status_code = 403,
        content = {"detail": "Forbidden: Invalid or missing Enterprise Gateway token."}
      )

    return await call_next(request)
