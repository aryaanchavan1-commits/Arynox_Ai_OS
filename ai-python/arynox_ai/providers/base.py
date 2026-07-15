"""Base AI Provider interface"""

from abc import ABC, abstractmethod
from typing import Optional


class AIProvider(ABC):
    """Abstract base class for all AI providers."""

    def __init__(self, config: dict):
        self.config = config
        self.api_key: str = config.get("api_key", "")
        self.base_url: str = config.get("base_url", "")
        self.default_model: str = config.get("default_model", "")
        self.temperature: float = config.get("temperature", 0.7)
        self.max_tokens: int = config.get("max_tokens", 4096)
        self._online: bool = False

    @abstractmethod
    async def chat(self, model: str, messages: list, stream: bool = False) -> dict:
        """Send a chat completion request."""
        pass

    @abstractmethod
    async def test(self) -> bool:
        """Test connection to the provider."""
        pass

    def is_online(self) -> bool:
        return self._online

    def _build_system_prompt(self, messages: list) -> list:
        """Ensure system message exists for context."""
        has_system = any(m.get("role") == "system" for m in messages)
        if not has_system:
            return [{"role": "system", "content": "You are Arynox AI, a helpful AI assistant integrated into the Arynox operating system."}] + messages
        return messages
