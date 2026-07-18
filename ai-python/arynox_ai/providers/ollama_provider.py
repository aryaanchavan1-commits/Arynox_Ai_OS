"""Ollama provider stub"""

import logging
from .base import AIProvider

logger = logging.getLogger("arynox.ai.providers.ollama")


class OllamaProvider(AIProvider):
    def __init__(self, config: dict):
        super().__init__(config)
        self.default_model = config.get("default_model", "llama3")
        self.base_url = config.get("base_url", "http://localhost:11434")

    async def chat(self, model: str, messages: list, stream: bool = False) -> dict:
        raise NotImplementedError("Ollama provider not yet implemented")

    async def test(self) -> bool:
        return False
