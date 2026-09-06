import os
import sys
import yaml
from typing import Dict, Any, Optional

def load_config(service_name: Optional[str], section: str, debug: bool = False) -> Optional[Dict[str, Any]]:
  """
  Safely loads mcp.conf.yml and extracts the specific configuration block.
  Resolves paths relative to the operational runtime working directory (NSSM context)
  to strictly prevent environment variable race conditions.
  """
  if debug is None:
    debug = False

  # DOS-13 ISOLATED RUNTIME RESOLUTION:
  # Get the isolated working directory set by NSSM AppDirectory (e.g., ~/.ai/venv/mcp)
  runtime_dir = os.getcwd()

  # Navigate 2 levels up to escape 'venv/mcp' and target the global '.ai' root
  ai_root = os.path.abspath(os.path.join(runtime_dir, "..", ".."))
  config_path = os.path.join(ai_root, "conf", "mcp.conf.yml")

  # Standalone/Interactive local script testing fallback (if executed outside standard tree)
  if not os.path.exists(config_path):
    home_dir = os.path.expanduser('~')
    config_path = os.path.join(home_dir, '.ai', 'conf', 'mcp.conf.yml')

  if not os.path.exists(config_path):
    print(f"[CRITICAL] Config missing at resolved path: {config_path}", file=sys.stderr, flush=True)
    return None

  try:
    with open(config_path, 'r', encoding='utf-8') as f:
      full_yaml = yaml.safe_load(f)

    if not full_yaml or section not in full_yaml:
      print(f"[ERROR] Section '{section}' not found in configuration", file=sys.stderr, flush=True)
      return None

    section_data = full_yaml[section]
    if not section_data or not isinstance(section_data, dict):
      return None

    # Case-insensitive direct lookup via dictionary mapping
    normalized_data = {str(k).strip().lower(): v for k, v in section_data.items()}

    if service_name:
      target_name = str(service_name).strip().replace("'", "").replace('"', "").lower()
      if target_name in normalized_data:
        return normalized_data[target_name]

    # Debug / Fallback strategy
    if debug or not service_name:
      available_keys = list(section_data.keys())
      if available_keys:
        fallback_key = available_keys
        print(f"[WARN] Fallback activated. Using node: '{fallback_key}'", file=sys.stderr, flush=True)
        return section_data[fallback_key]

    print(f"[ERROR] Target block '{service_name}' not found in section '{section}'", file=sys.stderr, flush=True)

  except Exception as e:
    print(f"[CRITICAL] Operational failure inside YAML config loader: {e}", file=sys.stderr, flush=True)

  return None
