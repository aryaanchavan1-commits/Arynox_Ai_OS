"""Gemini provider stub"""

import logging
from .base import AIProvider

logger = logging.getLogger("arynox.ai.providers.gemini")


class GeminiProvider(AIProvider):
    def __init__(self, config: dict):
        super().__init__(config)
        self.default_model = config.get("default_model", "gemini-pro")

    async def chat(self, model: str, messages: list, stream: bool = False) -> dict:
        raise NotImplementedError("Gemini provider not yet implemented")

    async def test(self) -> bool:
        return False
