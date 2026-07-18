"""LM Studio provider stub"""

import logging
from .base import AIProvider

logger = logging.getLogger("arynox.ai.providers.lm_studio")


class LMStudioProvider(AIProvider):
    def __init__(self, config: dict):
        super().__init__(config)
        self.default_model = config.get("default_model", "local-model")
        self.base_url = config.get("base_url", "http://localhost:1234/v1")

    async def chat(self, model: str, messages: list, stream: bool = False) -> dict:
        raise NotImplementedError("LM Studio provider not yet implemented")

    async def test(self) -> bool:
        return False
