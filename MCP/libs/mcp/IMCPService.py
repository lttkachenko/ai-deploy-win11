# /MCP/libs/mcp/IMCPService.py
from abc import ABC, abstractmethod
from typing import Any, Dict, List, Optional

from libs.store import IStoreServiceBase, StoreType


class IStoreConnector(ABC):
  """Интерфейс коннектора, отвечающего за инициализацию связи с вектор стором."""

  @abstractmethod
  async def get_store_client(self, raw_config: Dict[str, Any]) -> IStoreServiceBase:
    """Инициализирует, подключает и возвращает базовый сервис векторного хранилища."""
    pass

class IMCPService(ABC):
  """Интерфейс основного сервиса MCP сервера."""

  @abstractmethod
  async def initialize(self) -> None:
    """Первичная подготовка сервиса и подключение к зависимостям."""
    pass

  @abstractmethod
  async def list_directory(self, relative_path: str) -> List[Dict[str, Any]]:
    """Эмуляция 'ls -l' поверх метаданных векторов в базе."""
    pass

  @abstractmethod
  async def search_notes(self, query: str, relative_path: Optional[str] = None, limit: int = 5) -> List[Dict[str, Any]]:
    """Поиск заметок с поддержкой относительных путей и склеивания."""
    pass
