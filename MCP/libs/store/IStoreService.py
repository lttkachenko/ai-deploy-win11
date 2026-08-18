from abc import ABC, abstractmethod
from enum import Enum
from typing import Any, Dict, List

# SST Constants
VECTOR_SIZE = 768
EMBED_MODEL_NAME = 'nomic-ai/nomic-embed-text-v1.5'

class StoreType(Enum):
  """Supported VectorStoreService Types."""
  QDRANT = "qdrant"
  MILVUS = "milvus"
  CHROMA = "chroma"
  SUBASE = "supabase"

class IStoreServiceBase(ABC):
  """Базовый тонкий интерфейс для управления жизненным циклом подключения."""

  @abstractmethod
  async def connect(self) -> None:
    """Инициализация клиента и pre-flight проверка доступности базы."""
    pass

  @abstractmethod
  async def close(self) -> None:
    """Грациозное закрытие соединений и дескрипторов."""
    pass

class IStoreService(IStoreServiceBase):
  """VectorStoreService supabase class (VectorStoreService interface)."""

  @abstractmethod
  async def index_file(self, file_path: str) -> None:
    """Particular file parsing, chunking and embedding."""
    pass

  @abstractmethod
  async def watch_vault(self) -> None:
    """File system monitoring infinite loop init."""
    pass
