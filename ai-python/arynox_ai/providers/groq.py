"""Groq AI provider implementation"""

import json
import logging
from typing import Optional
import httpx

from .base import AIProvider

logger = logging.getLogger("arynox.ai.providers.groq")


class GroqProvider(AIProvider):
    def __init__(self, config: dict):
        super().__init__(config)
        self.base_url = config.get("base_url", "https://api.groq.com/openai/v1")
        self.default_model = config.get("default_model", "llama3-70b-8192")
        self.client = httpx.AsyncClient(
            base_url=self.base_url,
            headers={
                "Authorization": f"Bearer {self.api_key}",
                "Content-Type": "application/json",
            },
            timeout=60.0,
        )

    async def chat(self, model: str, messages: list, stream: bool = False) -> dict:
        messages = self._build_system_prompt(messages)

        payload = {
            "model": model or self.default_model,
            "messages": messages,
            "temperature": self.temperature,
            "max_tokens": self.max_tokens,
            "stream": stream,
        }

        try:
            if stream:
                return await self._stream_chat(payload)
            else:
                resp = await self.client.post("/chat/completions", json=payload)
                resp.raise_for_status()
                data = resp.json()
                self._online = True
                return {
                    "content": data["choices"][0]["message"]["content"],
                    "model": data["model"],
                    "usage": data.get("usage", {}),
                    "provider": "groq",
                }
        except Exception as e:
            logger.error(f"Groq chat error: {e}")
            self._online = False
            raise

    async def _stream_chat(self, payload: dict) -> dict:
        content_parts = []
        async with self.client.stream("POST", "/chat/completions", json=payload) as resp:
            resp.raise_for_status()
            async for line in resp.aiter_lines():
                if line.startswith("data: "):
                    data = line[6:]
                    if data.strip() == "[DONE]":
                        break
                    try:
                        chunk = json.loads(data)
                        delta = chunk.get("choices", [{}])[0].get("delta", {})
                        if "content" in delta:
                            content_parts.append(delta["content"])
                    except json.JSONDecodeError:
                        continue
        self._online = True
        return {
            "content": "".join(content_parts),
            "model": payload["model"],
            "provider": "groq",
        }

    async def test(self) -> bool:
        try:
            resp = await self.client.get("/models")
            resp.raise_for_status()
            self._online = True
            return True
        except Exception:
            self._online = False
            return False
