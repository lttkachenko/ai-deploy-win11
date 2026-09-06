# /libs/store/StoreServiceQdrantBase.py
import sys
import asyncio
import socket
import asyncio
from urllib.parse import urlparse
from typing import Dict, Any, List, Optional

from qdrant_client import AsyncQdrantClient
from sentence_transformers import SentenceTransformer

from .IStoreService import IStoreServiceBase, EMBED_MODEL_NAME

class StoreServiceQdrantBase(IStoreServiceBase):
  """Базовая реализация Qdrant для операций чтения, поиска и подключения."""

  def __init__(self, raw_config: Dict[str, Any]):
    self.client: Optional[AsyncQdrantClient] = None
    self._embedding_engine: Optional[SentenceTransformer] = None
    self._parse_config(raw_config)

  async def connect(self) -> None:
    """Обеспечивает подключение к Qdrant."""
    await self._await_store()

    self.client = AsyncQdrantClient(url = self.qdrant_url, api_key = self.api_key)
    print(f"[STORE-BASE] Успешное подключение к Qdrant: {self.qdrant_url}")

  async def close(self) -> None:
    """Закрытие сессий дескриптора клиента."""
    if self.client:
      await self.client.close()
      print("[STORE-BASE] Соединение с Qdrant разорвано.")

  # ==========================================
  # ПРИВАТНЫЕ УТИЛИТЫ ДЛЯ ПОИСКА (Нужны и серверу, и вотчеру)
  # ==========================================

  def _parse_config(self, raw_config: Dict[str, Any]) -> None:
    """Protected-метод парсинга общих параметров (DOS-12 адаптивный)."""
    if not raw_config:
      raise ValueError("[STORE-BASE] Критическая ошибка: Конфигурационная матрица (raw_config) пуста или равна None.")

    store_host = raw_config.get('store', 'http://127.0.0.1')
    store_port = raw_config.get('store_port') or raw_config.get('port') or 8093

    self.collection_name = (raw_config.get('db') or raw_config.get('store_db'))
    self.qdrant_url = f"{store_host}:{store_port}"
    self.api_key = raw_config.get('api_key')

  async def _await_store(self) -> None:
    """
    Protected block to check vector store availability before engine boot.
    Safely extracts pure host domain/IP to bypass socket.gaierror bugs.
    """
    print(f">>> Awaiting connection to vector store endpoint at: {self.qdrant_url}", flush=True)

    # 1. Clean the host parameter from schema prefixes (e.g., removes 'http://')
    parsed_url = urlparse(self.qdrant_url)
    pure_host = parsed_url.hostname or "127.0.0.1"

    # 2. Extract port safely from the gathered variables
    try:
      pure_port = int(parsed_url.port or self.qdrant_url.split(":")[-1])
    except Exception:
      pure_port = 8093

    # Remove unexpected bracket residues if urlparse misbehaved on raw strings
    pure_host = pure_host.replace("[", "").replace("]", "")

    while True:
      try:
        # Direct low-level socket connection test executed in a thread-safe way
        await asyncio.to_thread(self._check_network_socket, pure_host, pure_port)
        break  # Success! Qdrant node is reachable, escape the loop.
      except Exception:
        print(f" |-- [AWAIT] Vector store node ({pure_host}:{pure_port}) unreachable. Retrying socket hook in 5s...", flush=True)
        await asyncio.sleep(5)

  def _check_network_socket(self, host: str, port: int) -> None:
    """Synchronous low-level network socket test executor."""
    # socket.create_connection requires a clean host string without 'http://' prefix
    with socket.create_connection((host, port), timeout=2) as sock:
      _ = sock.gettimeout()

  async def _get_embedding(self, text: str, is_query: bool = False) -> List[float]:
    """Ленивая инициализация CPU-модели Nomic и генерация векторов."""
    try:
      if self._embedding_engine is None:
        print('>>> [LAZY BOOT] Initializing CPU Transformer Model...', file = sys.stderr)
        self._embedding_engine = SentenceTransformer(EMBED_MODEL_NAME, device = 'cpu')

      prefix = 'search_query: ' if is_query else 'search_document: '
      prefixed_text = prefix + text

      vector = await asyncio.to_thread(lambda: self._embedding_engine.encode(prefixed_text).tolist())
      return vector
    except Exception as e:
      print(f'[CRITICAL] Embedding extraction failed: {e}', file = sys.stderr)
      return []
