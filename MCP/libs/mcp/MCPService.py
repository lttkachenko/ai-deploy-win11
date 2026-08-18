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
    """PIPELINE A: Эмуляция виртуального дерева директорий (ls -l)."""
    print(f"[MCP-SERVICE] Скроллинг схемы папки для индекса: {target_folder}")

    scroll_result, _ = await self._store_client.client.scroll(
      collection_name = self._collection_name,
      scroll_filter = models.Filter(
        must = [models.FieldCondition(key = "metadata.folder", match = models.MatchValue(value = target_folder))]
      ),
      limit = 100,
      with_payload = ["metadata.file_name"],
      with_vectors = False
    )

    unique_files = sorted({
      point.payload.get("metadata", {}).get("file_name")
      for point in scroll_result if point.payload and "metadata" in point.payload
    })

    if not unique_files:
      return f"### Directory Map: obsidian://{target_folder}/\nВиртуальная директория пуста."

    ls_payload = f"### Content listing for virtual directory: obsidian://{target_folder}/\n"
    for f_name in unique_files:
      ls_payload += f"- [FILE] obsidian://{target_folder}/{f_name}\n"

    return ls_payload

  async def _reconstruct_file_from_shards(self, target_folder: str, sub_path: str) -> str:
    """PIPELINE B: Сборка текстовых осколков (shards) обратно в Markdown."""
    print(f"[MCP-SERVICE] Сборка векторных чанков для файла: '{sub_path}' в папке '{target_folder}'")

    file_points, _ = await self._store_client.client.scroll(
      collection_name = self._collection_name,
      scroll_filter = models.Filter(
          must=[
            models.FieldCondition(key = "metadata.folder", match = models.MatchValue(value = target_folder)),
            models.FieldCondition(key = "metadata.file_name", match = models.MatchText(text = sub_path))
          ]
      ),
      limit = 100,
      with_payload = True,
      with_vectors = False
    )

    # Резильентный фолбэк: если файл не найден, откатываемся к выводу списка папки
    if not file_points:
      print(f"[MCP-SERVICE] Файл '{sub_path}' отсутствует. Откат к маппингу директории.")
      return await self._build_virtual_directory_manifest(target_folder)

    # Сортируем куски по оригинальному chunk_id
    sorted_points = sorted(
        file_points,
        key = lambda x: x.payload.get("metadata", {}).get("chunk_id", 0) if x.payload else 0
    )

    # Склеиваем массив текстовых блоков в один поток
    compiled_doc = []
    first_payload = sorted_points[0].payload if (sorted_points and sorted_points[0].payload) else {}
    actual_title = first_payload.get("metadata", {}).get("file_name", sub_path)

    compiled_doc.append(f"# KNOWLEDGE SOURCE: obsidian://{target_folder}/{actual_title}\n")
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
