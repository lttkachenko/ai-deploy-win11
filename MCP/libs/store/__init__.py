# /libs/store/__init__.py
from typing import Dict, Any

# Импортируем интерфейсы, константы и энум из соседнего модуля через точку
from .IStoreService import StoreType, IStoreServiceBase, IStoreService, VECTOR_SIZE, EMBED_MODEL_NAME
from .StoreServiceQdrantBase import StoreServiceQdrantBase
from .StoreServiceQdrant import StoreServiceQdrant

class StoreFactoryBase:
  """Фабрика для сборки базового инстанса хранилища (для чтения/поиска)."""

  @staticmethod
  def create_service(store_type: StoreType, raw_config: Dict[str, Any]) -> IStoreServiceBase:
    if store_type == StoreType.QDRANT:
      return StoreServiceQdrantBase(raw_config = raw_config)

    raise NotImplementedError(f"Базовый сервис для хранилища {store_type.value} не реализован.")

class StoreFactory:
  """Фабрика для сборки полноценного инстанса хранилища (для индексации/вотчера)."""

  @staticmethod
  def create_service(store_type: StoreType, raw_config: Dict[str, Any]) -> IStoreService:
    if store_type == StoreType.QDRANT:
      return StoreServiceQdrant(raw_config = raw_config)

    raise NotImplementedError(f"Полный сервис для хранилища {store_type.value} не реализован.")
