# /MCP/libs/mcp/StoreConnectorFactory.py
from libs.store import StoreType
from .IMCPService import IStoreConnector
from .StoreConnectorQdrant import StoreConnectorQdrant


class StoreConnectorFactory:
  """Factory to resolve and instantiate specific vector store connectors."""

  @staticmethod
  def create_connector(store_type: StoreType) -> IStoreConnector:
    if store_type == StoreType.QDRANT:
      return StoreConnectorQdrant()

    raise NotImplementedError(f"Connector for store type {store_type.value} is not implemented.")
