# mcp_server.py - Clean Architecture FastMCP Server Gateway Launcher
import os
import sys
import argparse

import libs
from libs.mcp import MCPGateway

# Принудительный сброс буфера логов для Windows NSSM
try:
  sys.stdout.reconfigure(line_buffering=True)
  sys.stderr.reconfigure(line_buffering=True)
except (OSError, AttributeError):
  pass

current_runtime_dir = os.path.dirname(os.path.abspath(__file__))
if current_runtime_dir not in sys.path:
  sys.path.insert(0, current_runtime_dir)

def parse_cli_arguments() -> argparse.Namespace:
  """Парсинг CLI аргументов запуска сервиса."""
  parser = argparse.ArgumentParser(description='MCP Server Explicit Class Gateway')
  parser.add_argument('-n', '--service_name', type=str, default=None, help='NSSM service registry target')
  parser.add_argument('-d', '--debug', action='store_true', help='Activate isolated debug configs')

  return parser.parse_args()

def main() -> None:
  # 1. Извлекаем CLI аргументы
  cli_args = parse_cli_arguments()

  # 2. Очищаем имя службы от Windows-мусора
  clean_service_name = None
  if cli_args.service_name:
    clean_service_name = (
      str(cli_args.service_name)
      .strip()
      .replace("'", "")
      .replace('"', "")
      .replace('\r', "")
      .replace('\n', "")
    )

  is_debug = True if cli_args.debug else False

  # 3. Загружаем изолированную конфигурацию окружения
  env_config = libs.load_config(
    service_name=clean_service_name,
    section='servers',
    debug=is_debug
  )

  if not env_config:
    raise RuntimeError(f"[FATAL] Server configuration block '{clean_service_name}' could not be resolved.")

  # 4. FIXED: Инициализируем объект правильного класса шлюза из пакета
  gateway = MCPGateway(runtime_env=env_config)
  gateway.start()

if __name__ == '__main__':
  main()
