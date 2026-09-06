# /MCP/libs/mcp/StoreConnectorQdrant.py
from typing import Dict, Any
from libs.store import StoreFactoryBase, StoreType, IStoreServiceBase
from .IMCPService import IStoreConnector

class StoreConnectorQdrant(IStoreConnector):
  """Коннектор для инициализации соединения с Qdrant через базовый класс хранилища."""

  async def get_store_client(self, raw_config: Dict[str, Any]) -> IStoreServiceBase:
    # Используем фабрику базового уровня (без вотчера и маркдаун-обвязки)
    store_client = StoreFactoryBase.create_service(store_type = StoreType.QDRANT, raw_config = raw_config)
    # Асинхронно подключаемся к базе
    await store_client.connect()

    return store_client
