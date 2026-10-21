# /MCP/libs/mcp/MCPService.py
import os
import json
from typing import Dict, Any, List, Optional
from qdrant_client import models

from libs.store import StoreType, StoreServiceQdrantBase
from .IMCPService import IMCPService
from .StoreConnectorFactory import StoreConnectorFactory

class MCPService(IMCPService):
  """Основной класс сервиса MCP сервера (сборка чанков, ls -l, резолв URI)."""

  def __init__(self, raw_config: Dict[str, Any], store_type: StoreType = StoreType.QDRANT):
    self._raw_config = raw_config
    self._store_type = store_type

    # Окончательный приватный парсинг конфигурации в ините инстанса
    self._parse_config(raw_config)

    self._store_connector = None
    self._store_client: Optional[StoreServiceQdrantBase] = None

  # ==========================================
  # ПУБЛИЧНЫЕ МЕТОДЫ
  # ==========================================

  async def initialize(self) -> None:
    """Асинхронный запуск коннекторов и подготовка клиента базы."""
    self._store_connector = StoreConnectorFactory.create_connector(self._store_type)
    self._store_client = await self._store_connector.get_store_client(self._raw_config)
    print(f"[MCP-SERVICE] Инициализирован поверх коллекции: {self._collection_name}")

  async def handle_uri_transaction(self, full_uri: str) -> str:
    """
    Унифицированный транзакционный движок (перенесён и причёсан из mcp_api.py).
    - Без sub-path -> компилирует структуру папки (ls -l эмуляция)
    - С sub-path -> склеивает векторные осколки обратно в Markdown заметку
    """
    if not self._store_client or not self._store_client.client:
      raise RuntimeError("Инфраструктурный лок: Клиент векторного хранилища не инициализирован.")

    print(f"[MCP-SERVICE] Транзакция для локатора: {full_uri}")

    # Очищаем префикс протокола
    clean_path = full_uri.replace("obsidian://", "")
    path_parts = [part for part in clean_path.split("/") if part]

    if not path_parts:
      # Корневой фолбэк, если прилетел пустой URI
      return (
        "### Obsidian Knowledge Base Vault Root\n"
        "- obsidian://Artifacts/\n- obsidian://Insights/\n"
        "- obsidian://Prompts/\n- obsidian://Roles/\n"
        "- obsidian://Skills/\n- obsidian://User/"
      )

    target_folder = path_parts[0]
    sub_path = "/".join(path_parts[1:]) if len(path_parts) > 1 else ""

    # Перенаправляем пайплайн в зависимости от наличия конкретного файла в URI
    if not sub_path:
      return await self._build_virtual_directory_manifest(target_folder)

    return await self._reconstruct_file_from_shards(target_folder, sub_path)

  # ==========================================
  # ПРИВАТНЫЕ МЕТОДЫ: СЛУЖЕБНЫЕ И ОБРАБОТКА ВЕКТОРОВ
  # ==========================================

  def _parse_config(self, raw_config: Dict[str, Any]) -> None:
    """Приватный метод парсинга параметров сервера."""
    if not raw_config:
      raise ValueError("[MCP-SERVICE] Критическая ошибка: raw_config не может быть None.")

    # Поддерживаем всю матрицу ключей DOS-12/13 для коллекции Qdrant
    self._collection_name = (raw_config.get('store_db') or raw_config.get('db') or raw_config.get('collection_name'))

    if not self._collection_name:
      raise ValueError("[MCP-SERVICE] Критическая ошибка: в конфигурации сервера отсутствует имя коллекции ('store_db' / 'db').")

    # Нам также может быть полезен адрес стора для отладки
    self._qdrant_url = raw_config.get('store') or raw_config.get('qdrant_url', 'http://127.0.0.1:6333')
    print(f"[MCP-SERVICE] Логика транзакций привязана к векторной коллекции: '{self._collection_name}'")

  async def _build_virtual_directory_manifest(self, target_folder: str) -> str:
    """PIPELINE A: Generates virtual directory listings by scanning Qdrant metadata."""
    print(f"[MCP-SERVICE] Building virtual file structure for directory: '{target_folder}'", flush = True)

    # Query Qdrant for any points belonging to this folder matching parent_path key
    scroll_result, _ = await self._store_client.client.scroll(
      collection_name = self._collection_name,
      scroll_filter = models.Filter(
        must = [
          models.FieldCondition(key = "metadata.parent_path", match = models.MatchValue(value = target_folder))
        ]
      ),
      limit = 100,
      with_payload = True,
      with_vectors = False
    )

    if not scroll_result:
      return f"### Virtual Directory Error\nFolder 'obsidian://{target_folder}' contains no vectorized assets."

    unique_files = set()
    for point in scroll_result:
      if point.payload and "metadata" in point.payload:
        meta = point.payload["metadata"]
        # Pull from verified uri_path or source_file keys used by the watcher
        raw_name = meta.get("uri_path") or meta.get("source_file") or "Unnamed"
        clean_name = raw_name.split("/")[-1] if "/" in str(raw_name) else raw_name
        if clean_name and clean_name != "Unnamed":
          unique_files.add(clean_name)

    manifest_lines = []
    manifest_lines.append(f"### Content listing for virtual directory: obsidian://{target_folder}/")
    if not unique_files:
      manifest_lines.append("*No document assets found mapping to this directory path node.*")
    else:
      for doc_name in sorted(unique_files):
        manifest_lines.append(f"- [FILE] obsidian://{target_folder}/{doc_name}")

    return "\n".join(manifest_lines)

  async def _reconstruct_file_from_shards(self, target_folder: str, sub_path: str) -> str:
    """PIPELINE B: Reconstruct text shards back into Markdown using verified uri_path keys."""
    # Reconstruct the exact uri pattern that the watcher script inserts into Qdrant
    target_uri_path = f"{target_folder}/{sub_path}"
    print(f"[MCP-SERVICE] Assembling shards for file via uri_path: '{target_uri_path}'", flush = True)

    file_points, _ = await self._store_client.client.scroll(
      collection_name = self._collection_name,
      scroll_filter = models.Filter(
        must = [
          # Targeted lookup against the verified metadata field layout
          models.FieldCondition(key = "metadata.uri_path", match = models.MatchValue(value = target_uri_path))
        ]
      ),
      limit = 100,
      with_payload = True,
      with_vectors = False
    )

    # Secondary fallback check: try matching just the filename if the full combined path fails
    if not file_points:
      print(f"[MCP-SERVICE] Targeted lookup failed for '{target_uri_path}'. Retrying with sub_path...", flush = True)
      file_points, _ = await self._store_client.client.scroll(
        collection_name = self._collection_name,
        scroll_filter = models.Filter(
          must = [
            models.FieldCondition(key = "metadata.parent_path", match = models.MatchValue(value = target_folder)),
            models.FieldCondition(key = "metadata.uri_path", match = models.MatchValue(value = sub_path))
          ]
        ),
        limit = 100,
        with_payload = True,
        with_vectors = False
      )

    # Ultimate fallback sequence to directory manifest map
    if not file_points:
      print(f"[MCP-SERVICE] Shards completely missing for '{sub_path}'. Invoking fallback map.", flush = True)
      return await self._build_virtual_directory_manifest(target_folder)

    # Standard chunk assembly implementation block
    sorted_points = sorted(
      file_points,
      key = lambda x: x.payload.get("metadata", {}).get("chunk_id", 0) if x.payload else 0
    )

    compiled_doc = []
    compiled_doc.append(f"# KNOWLEDGE SOURCE: obsidian://{target_folder}/{sub_path}\n")
    for point in sorted_points:
      if point.payload and "text" in point.payload:
        compiled_doc.append(point.payload["text"])

    return "\n".join(compiled_doc)

  async def list_directory(self, relative_path: str) -> List[Dict[str, Any]]:
    """Заглушка под будущую REST-валидацию JSON-структур (интерфейсный контракт)."""
    pass

  async def search_notes(self, query: str, relative_path: Optional[str] = None, limit: int = 5) -> List[Dict[str, Any]]:
    """Заглушка под будущую REST-валидацию JSON-структур (интерфейсный контракт)."""
    pass
