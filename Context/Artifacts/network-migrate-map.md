### 🗺️ Network Port Matrix Architecture (Audit & Relocation Matrix)

| Service | Default Port | Enterprise Conflict Risks & Status | Target Secure Port | Configuration File Mapping Path |
| :--- | :--- | :--- | :--- | :--- |
| llama-server | 8080, 8081, 8082 | Critical Inbound Collision Risk. Ports 8080 and 8081 are globally saturated by localized dev environments (Webpack, Apache, Spring Boot). | 18080, 18081, 18082 | conf/llama-swap.conf.yml (via --port port parameter injected into the active cmd literal block string context). |
| llama-swap (Go-Proxy Engine) | 1234 | Moderate Risk. Port 1234 is occasionally bound by custom legacy utilities, requiring complete isolation. | 11234 | Backend/backend_deploy.ps1 (passed natively as a rigid runtime execution flag constraint during service registration loops). |
| Qdrant REST API (Docker) | 6333 | Low Risk / Safe Zone. Highly specialized vector store endpoint database socket. Preserved as original defaults. | 6333 | Qdrant/docker-compose.yml (under ports binding matrix) and mirrored inside conf/mcp.conf.yml. |
| Qdrant gRPC API (Docker) | 6334 | Low Risk / Safe Zone. Internal high-performance binary transmission socket paired directly with the REST layer. | 6334 | Qdrant/docker-compose.yml (under ports declarative binding matrix layout rules). |
| FastMCP SSE Server (Win-Daemon) | 8000 | High Cross-Boundary Collision Risk. Port 8000 is the default playground socket for Python backends (FastAPI, Django). | 18000 | Qdrant/qdrant_mcp.py (or explicitly mapped as an immutable runtime argument block within qdrant_deploy.ps1). |
