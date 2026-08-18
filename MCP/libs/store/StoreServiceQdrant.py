# /libs/store/StoreServiceQdrant.py
import os
import re
import sys
import hashlib
import asyncio
from functools import partial
from typing import Dict, Any, List, Set, Optional

from watchfiles import awatch
from qdrant_client.models import PointStruct, Filter, FieldCondition, MatchValue, FilterSelector
from langchain_text_splitters import MarkdownHeaderTextSplitter

from .IStoreService import IStoreService
from .StoreServiceQdrantBase import StoreServiceQdrantBase

class StoreServiceQdrant(StoreServiceQdrantBase, IStoreService):
  """Полноценный сервис индексации Obsidian Vault с интеграцией в Qdrant."""

  def __init__(self, raw_config: Dict[str, Any]):
    super().__init__(raw_config = raw_config)

    self.store: str = "qdrant_indexed"

    if not self.vault_path:
      raise ValueError("[STORE] Критическая ошибка: для работы вотчера необходим 'vault_path' в конфиге.")

    print(f"[STORE-INDEXER] Конструктор наследника успешно инициализирован. Свойство store: {self.store}")

  # ==========================================
  # ПУБЛИЧНЫЕ МЕТОДЫ И ОБВЯЗКА ОБСИДИАНА (Только для вотчера)
  # ==========================================

  async def index_file(self, file_path: str) -> None:
    """Пайплайн чтения, разбиения на чанки, эмбеддинга и синхронизации с Qdrant."""
    if not file_path.endswith('.md') or self.client is None:
      return

    try:
      relative_raw_path = os.path.relpath(file_path, self.vault_path)
      uri_path = os.path.splitext(relative_raw_path)[0].replace('\\', '/')
      parent_path = os.path.dirname(uri_path)

      chunks = await asyncio.to_thread(self._parse_markdown_to_chunks, file_path)

      if chunks is None:
        await self._delete_file_vectors(uri_path)
        print(f'[PURGED] Removed obsolete vectors for: {uri_path}')
        return

      if not chunks:
        return

      points = await self._prepare_qdrant_points(chunks, file_path, uri_path, parent_path)

      if points:
        await self._delete_file_vectors(uri_path)
        await self.client.upsert(collection_name = self.collection_name, points = points)
        print(f'[SUCCESS] Indexed URI: {uri_path} (Parent: /{parent_path if parent_path else "root"})')
    except Exception as e:
      print(f'[ERROR] Failed to index {file_path}: {e}', file = sys.stderr)

  async def watch_vault(self) -> None:
    """Основной бесконечный цикл отслеживания изменений в Obsidian Vault."""
    if not self.vault_path:
      raise ValueError("Невозможно запустить вотчер: в конфигурации отсутствует vault_path.")

    print('[SUCCESS] Vault hydration completed. Syncing real-time mutations...', file = sys.stdout)
    print(f'\n[ONLINE] Graph-Aware Async RAG Daemon listening on: {self.vault_path}', file = sys.stdout)

    async for changes in awatch(self.vault_path):
      for change_type, file_path in changes:
        await self.index_file(file_path = file_path)

  # ==========================================
  # ПРИВАТНЫЕ МЕТОДЫ И ОБВЯЗКА ОБСИДИАНА (Только для вотчера)
  # ==========================================

  def _parse_config(self, raw_config: Dict[str, Any]) -> None:
    """Перегруженный protected-метод парсинга параметров вотчера."""
    super()._parse_config(raw_config)

    self.vault_path: Optional[str] = raw_config.get('vault')

    if not self.vault_path:
      raise ValueError(
        "[STORE] Критическая ошибка запуска: в секции конфигурации вотчера "
        "отсутствует обязательный параметр 'vault'."
      )

    print(f"[STORE-INDEXER] Конфигурация успешно распарсена для волта: {self.vault_path}")

  def _parse_markdown_to_chunks(self, file_path: str) -> Optional[List[Any]]:
    """Синхронный пайплайн чтения, резолва трансклюзий и нарезки маркдауна."""
    if not os.path.exists(file_path):
      return None

    with open(file_path, 'r', encoding = 'utf-8') as f:
      raw_content = f.read()

    vault_file_index = self._update_vault_index()
    expanded_content = self._resolve_transclusions(raw_content, file_path, vault_file_index)
    cleaned_content = self._clean_markdown(expanded_content)

    if not cleaned_content:
      return []

    headers_to_split_on = [('#', 'Header1'), ('##', 'Header2'), ('###', 'Header3')]
    splitter = MarkdownHeaderTextSplitter(headers_to_split_on = headers_to_split_on)

    return splitter.split_text(cleaned_content)

  async def _prepare_qdrant_points(
      self, chunks: List[Any], file_path: str, uri_path: str, parent_path: str
  ) -> List[PointStruct]:
    """Асинхронная подготовка структуры точек Qdrant (вызывает родительский _get_embedding)."""
    points = []
    for i, chunk in enumerate(chunks):
      text_payload = chunk.page_content
      if not text_payload.strip():
        continue

      metadata = chunk.metadata.copy()
      metadata['source_file'] = os.path.basename(file_path)
      metadata['uri_path'] = uri_path
      metadata['parent_path'] = parent_path
      metadata['lang'] = self._detect_language(text_payload)

      # Вызов метода генерации вектора из базового класса!
      vector = await self._get_embedding(text_payload, is_query = False)
      if not vector:
        continue

      seed_string = f"{file_path}_{i}"
      hash_hex = hashlib.sha256(seed_string.encode('utf-8')).hexdigest()
      point_id = int(hash_hex[:16], 16)

      points.append(
        PointStruct(id = point_id, vector = vector, payload = {'text': text_payload, 'metadata': metadata})
      )

    return points

  async def _delete_file_vectors(self, uri_path: str) -> None:
    """Удаление всех существующих чанков файла из коллекции Qdrant."""
    await self.client.delete(
      collection_name = self.collection_name,
      points_selector = FilterSelector(
        filter=Filter(must = [FieldCondition(key = 'metadata.uri_path', match = MatchValue(value = uri_path))])
      )
    )

  def _update_vault_index(self) -> Dict[str, str]:
    """Составление карты плоских имён документов для резолва трансклюзий."""
    new_index = {}
    for root, _, files in os.walk(self.vault_path):
      for file in files:
        if file.endswith('.md'):
          note_name = os.path.splitext(file)[0]
          new_index[note_name] = os.path.join(root, file)

    return new_index

  def _resolve_transclusions(self, content: str, current_file_path: str, vault_file_index: Dict[str, str], visited: Optional[Set[str]] = None) -> str:
    """Рекурсивный резолв ссылок типа ![[Note]] (Плоская структура)."""
    if visited is None:
        visited = set()

    abs_current_path = os.path.abspath(current_file_path)
    if abs_current_path in visited:
      return ''

    pattern = r'!\[\[([^\]|#]+)(?:#[^\]]*)?\]\]'

    visited.add(abs_current_path)
    bound_replace_callback = partial(self._replace_transclusion_match, vault_file_index, visited)

    return re.sub(pattern, bound_replace_callback, content)

  def _replace_transclusion_match(self, vault_file_index: Dict[str, str], visited: Set[str], match: re.Match) -> str:
    """Приватный метод обработки отдельного совпадения ссылки на заметку."""
    note_name = match.group(1).strip()
    target_path = vault_file_index.get(note_name)

    if target_path and os.path.exists(target_path):
      try:
        with open(target_path, 'r', encoding = 'utf-8') as f:
          child_content = f.read()

        child_content = re.sub(r'^---[\s\S]*?---', '', child_content).strip()

        return self._resolve_transclusions(child_content, target_path, vault_file_index, visited.copy())
      except Exception:
        return f'\n[ERROR: Failed to resolve transclusion for {note_name}]\n'

    return match.group(0)

  def _clean_markdown(self, content: str) -> str:
    """Очистка метаданных (frontmatter) и вики-ссылок."""
    content = re.sub(r'^---[\s\S]*?---', '', content)
    content = re.sub(r'\[\[([^\]|]+)(?:\|[^\]]*)?\]\]', r'\1', content)

    return content.strip()

  def _detect_language(self, text: str) -> str:
    """Определение языка контента."""
    if bool(re.search('[а-яА-ЯёЁ]', text)):
      return 'ru'
    return 'en'
