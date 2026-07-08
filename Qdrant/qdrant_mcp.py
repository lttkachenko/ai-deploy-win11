import sys
import argparse
import requests
from mcp.server.fastmcp import FastMCP

# --- Parse Target Collection Allocation ---
parser = argparse.ArgumentParser(description="Gheimher Automated FastMCP Qdrant Bridge")
parser.add_argument(
  "--collection",
  type=str,
  default="db-dev",
  help="Target Qdrant collection to query (e.g., db-dev, db-hobby)"
)
# FastMCP parses sys.argv by default, so we extract our flag and purge sys.argv to prevent conflicts
args, unknown = parser.parse_known_args()
sys.argv = [sys.argv[0]] + unknown

TARGET_COLLECTION = args.collection

# --- Configuration Constants ---
# Operating inside WSL2, 'win-host' alias maps via network_setup.ps1 loopback routes
QDRANT_URL = "http://win-host:6333"
OLLAMA_URL = "http://win-host:11434/api/embed"
EMBED_MODEL = "nomic-embed-text"

# Initialize FastMCP Server Node named dynamically after the target space
mcp = FastMCP(f"Qdrant-RAG-{TARGET_COLLECTION}")

def get_query_embedding(query_text: str) -> list:
  """Fetch structured vector coefficients from host Ollama embedding instance."""
  try:
    response = requests.post(OLLAMA_URL, json={"model": EMBED_MODEL, "input": query_text}, timeout=5)
    response.raise_for_status()
    return response.json()["embeddings"]
  except Exception as e:
    print(f"[CRITICAL] Embedding extraction failed via Ollama: {str(e)}", file=sys.stderr)
    return []

@mcp.tool()
def search_knowledge_base(query: str, limit: int = 5) -> str:
  """
  Search the local structural knowledge base collection for relevant contexts, guidelines, and rules.
  Use this tool whenever the user asks about system architecture, specific configs, roles, deployment steps, or code guidelines.
  """
  vector = get_query_embedding(query)
  if not vector:
    return "Error: Unable to generate query vector coefficients from local inference hub."

  search_endpoint = f"{QDRANT_URL}/collections/{TARGET_COLLECTION}/points/search"
  payload = {
    "vector": vector,
    "limit": limit,
    "with_payload": True
  }

  try:
    res = requests.post(search_endpoint, json=payload, timeout=5)
    res.raise_for_status()
    results = res.json().get("result", [])

    if not results:
      return f"No relevant context blocks identified within the target collection: '{TARGET_COLLECTION}'."

    formatted_chunks = []
    for match in results:
      score = match.get("score", 0.0)
      data = match.get("payload", {})
      text = data.get("text", "[Empty Payload]")
      metadata = data.get("metadata", {})
      source = metadata.get("source_file", "Unknown Origin")

      # Formatting block structure with clean cross-platform references
      formatted_chunks.append(
        f"--- CONTEXT BLOCK (Source: {source} | Cosine Match Score: {score:.4f}) ---\n{text}\n"
      )

    return "\n".join(formatted_chunks)

  except Exception as e:
    return f"CRITICAL: Failed to query vector storage engine at {TARGET_COLLECTION}. Internal Trace: {str(e)}"

if __name__ == "__main__":
  print(f">>> Launching FastMCP Gateway targeting Qdrant Collection Space: [{TARGET_COLLECTION}]", file=sys.stderr)
  mcp.run(transport="stdio")
