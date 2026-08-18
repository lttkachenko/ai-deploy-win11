# mcp_watcher.py - Clean Architecture RAG Filesystem Runner
import os
import sys
import argparse
import asyncio
import traceback

import libs
from libs.store import StoreFactory, StoreType

# Принудительный сброс буфера для логов NSSM в Windows
try:
  sys.stdout.reconfigure(line_buffering=True)
  sys.stderr.reconfigure(line_buffering=True)
except (OSError, AttributeError):
  pass

current_runtime_dir = os.path.dirname(os.path.abspath(__file__))
if current_runtime_dir not in sys.path:
  sys.path.insert(0, current_runtime_dir)

def parse_args():
  """Парсинг CLI аргументов запуска службы."""
  parser = argparse.ArgumentParser(description = 'MCP Watcher Daemon')
  parser.add_argument('-n', '--service_name', type = str, default = None, help = 'NSSM service name')
  parser.add_argument('-d', '--debug', action = 'store_true', default = False, help = 'Enable debug mode')

  return parser.parse_args()

async def run_async_watcher():
  args = parse_args()

  # 1. Immediate STDOUT dump of incoming CLI arguments from Windows NSSM
  print(f"[LAUNCH-DEBUG] Process started. CLI Arguments -> service_name: '{args.service_name}', debug_mode: {args.debug}", flush = True)

  clean_service_name = None
  if args.service_name:
    clean_service_name = (
      str(args.service_name)
      .strip()
      .replace("'", "")
      .replace('"', "")
      .replace('\r', "")
      .replace('\n', "")
    )

  is_debug = False
  if args.debug is True:
    is_debug = True

  print(f"[LAUNCH-DEBUG] Cleaned CLI Arguments -> service_name: '{clean_service_name}', debug_mode: {is_debug}", flush = True)

  # Primary config loading via the shared library
  raw_config = libs.load_config(clean_service_name, 'watchers', is_debug)

  # 2. Immediate STDOUT dump of the resolved configuration structure
  if raw_config is None:
    print("[LAUNCH-DEBUG] Factory block rejection: 'raw_config' is completely None!", flush = True)
  elif isinstance(raw_config, dict):
    received_keys = ", ".join(list(raw_config.keys()))
    print(f"[LAUNCH-DEBUG] Factory block accepted. Received dictionary keys: [{received_keys}]", flush = True)
  else:
    print(f"[LAUNCH-DEBUG] Factory block anomaly: 'raw_config' returned unexpected type: {type(raw_config)}", flush = True)

  # 3. Initialize full service via Factory (will raise ValueError if raw_config is None)
  service = StoreFactory.create_service(
    store_type = StoreType.QDRANT,
    raw_config = raw_config
  )

  # Start the service lifecycle
  await service.connect()
  try:
    await service.watch_vault()
  finally:
    await service.close()

if __name__ == '__main__':
  try:
    asyncio.run(run_async_watcher())
  except KeyboardInterrupt:
    print('\n[OFFLINE] Async RAG Watcher Daemon gracefully terminated.', file=sys.stdout, flush = True)
  except Exception as e:
    print(f'[FATAL] Startup crash: {e}', file=sys.stderr, flush = True)
    traceback.print_exc(file=sys.stderr)
    sys.exit(1)
