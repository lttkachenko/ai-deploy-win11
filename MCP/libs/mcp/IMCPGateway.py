# /MCP/libs/mcp/IMCPServerGateway.py
from abc import ABC, abstractmethod
from fastapi.responses import JSONResponse

class IMCPGateway(ABC):
  """Интерфейс управляющего шлюза MCP сервера."""

  @abstractmethod
  async def on_startup(self) -> None:
    """Асинхронный хук инициализации зависимостей при старте приложения."""
    pass

  @abstractmethod
  async def on_shutdown(self) -> None:
    """Грациозное закрытие коннекторов баз данных при остановке сервера."""
    pass

  @abstractmethod
  async def health_check(self) -> JSONResponse:
    """HTTP GET эндпоинт проверки здоровья инфраструктуры."""
    pass

  @abstractmethod
  async def dynamic_resource_router(self, folder: str, path: str) -> str:
    """Маршрутизация запросов виртуальных файлов Obsidian."""
    pass

  @abstractmethod
  async def dynamic_prompt_router(self, prompt_name: str) -> str:
    """Вызов шаблонов промптов."""
    pass

  @abstractmethod
  def start(self) -> None:
    """Запуск ASGI-сервера uvicorn."""
    pass
