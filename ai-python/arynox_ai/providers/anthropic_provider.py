"""Anthropic provider stub"""

import logging
from .base import AIProvider

logger = logging.getLogger("arynox.ai.providers.anthropic")


class AnthropicProvider(AIProvider):
    def __init__(self, config: dict):
        super().__init__(config)
        self.default_model = config.get("default_model", "claude-3-opus-20240229")

    async def chat(self, model: str, messages: list, stream: bool = False) -> dict:
        raise NotImplementedError("Anthropic provider not yet implemented")

    async def test(self) -> bool:
        return False
