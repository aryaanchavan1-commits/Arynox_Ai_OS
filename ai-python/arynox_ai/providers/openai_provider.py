"""OpenAI provider stub"""

import logging
from .base import AIProvider

logger = logging.getLogger("arynox.ai.providers.openai")


class OpenAIProvider(AIProvider):
    def __init__(self, config: dict):
        super().__init__(config)
        self.default_model = config.get("default_model", "gpt-4")

    async def chat(self, model: str, messages: list, stream: bool = False) -> dict:
        raise NotImplementedError("OpenAI provider not yet implemented")

    async def test(self) -> bool:
        return False
