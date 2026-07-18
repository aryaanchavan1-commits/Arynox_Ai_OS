"""Arynox AI Runtime - Main entry point"""

import asyncio
import json
import logging
import os
from pathlib import Path
from typing import Optional

import dbus_next
from dbus_next.aio import MessageBus
from dbus_next.service import ServiceInterface, method, signal

from .providers.base import AIProvider
from .providers.groq import GroqProvider
from .providers.openai_provider import OpenAIProvider
from .providers.anthropic_provider import AnthropicProvider
from .providers.gemini_provider import GeminiProvider
from .providers.ollama_provider import OllamaProvider
from .providers.lm_studio import LMStudioProvider
from .memory.store import MemoryStore
from .config import RuntimeConfig

logger = logging.getLogger("arynox.ai")


class AIRuntimeInterface(ServiceInterface):
    def __init__(self, runtime: "AIRuntime"):
        super().__init__("org.arynox.AiRuntime")
        self.runtime = runtime

    @method()
    async def Chat(self, provider: 's', model: 's', messages: 's', stream: 'b') -> 's':
        result = await self.runtime.chat(provider, model, json.loads(messages), stream)
        return json.dumps(result)

    @method()
    async def GetProviders(self) -> 's':
        return json.dumps(self.runtime.get_provider_status())

    @method()
    async def GetMemory(self, limit: 'i' = 50) -> 's':
        return json.dumps(await self.runtime.get_memory(limit))

    @method()
    async def ClearMemory(self):
        await self.runtime.clear_memory()

    @method()
    async def TestConnection(self, provider: 's') -> 's':
        result = await self.runtime.test_connection(provider)
        return json.dumps({"success": result})


class AIRuntime:
    def __init__(self, config_path: str = "/etc/arynox/ai-runtime.yaml"):
        self.config = RuntimeConfig.load(config_path)
        self.memory = MemoryStore(self.config.db_path)
        self.providers: dict[str, AIProvider] = {}
        self._init_providers()

    def _init_providers(self):
        registry = {
            "groq": GroqProvider,
            "openai": OpenAIProvider,
            "anthropic": AnthropicProvider,
            "gemini": GeminiProvider,
            "ollama": OllamaProvider,
            "lmstudio": LMStudioProvider,
        }
        for name, provider_cls in registry.items():
            cfg = self.config.providers.get(name, {})
            try:
                self.providers[name] = provider_cls(cfg)
                logger.info(f"Initialized provider: {name}")
            except Exception as e:
                logger.warning(f"Failed to initialize provider {name}: {e}")

    async def chat(self, provider_name: str, model: str, messages: list, stream: bool = False) -> dict:
        provider = self.providers.get(provider_name)
        if not provider:
            return {"error": f"Unknown provider: {provider_name}"}

        try:
            response = await provider.chat(model, messages, stream=stream)
            await self.memory.store_conversation(provider_name, model, messages, response)
            return response
        except Exception as e:
            logger.error(f"Chat error: {e}")
            return {"error": str(e)}

    def get_provider_status(self) -> list[dict]:
        return [
            {
                "name": name,
                "online": p.is_online(),
                "model": p.default_model,
            }
            for name, p in self.providers.items()
        ]

    async def get_memory(self, limit: int = 50) -> list[dict]:
        return await self.memory.get_recent(limit)

    async def clear_memory(self):
        await self.memory.clear()

    async def test_connection(self, provider_name: str) -> bool:
        provider = self.providers.get(provider_name)
        if not provider:
            return False
        try:
            result = await provider.test()
            return result
        except Exception:
            return False

    async def run_dbus(self):
        bus = await MessageBus(bus_type=dbus_next.BusType.SESSION).connect()
        interface = AIRuntimeInterface(self)
        bus.export("/org/arynox/AiRuntime", interface)
        await bus.request_name("org.arynox.AiRuntime")
        logger.info("AI Runtime D-Bus service ready")
        await asyncio.Event().wait()

    async def run_http(self, host: str = "127.0.0.1", port: int = 8741):
        from fastapi import FastAPI
        import uvicorn

        app = FastAPI(title="Arynox AI Runtime")

        @app.post("/v1/chat")
        async def chat_endpoint(provider: str, model: str, messages: list, stream: bool = False):
            return await self.chat(provider, model, messages, stream)

        @app.get("/v1/providers")
        async def providers_endpoint():
            return self.get_provider_status()

        @app.get("/v1/health")
        async def health():
            return {"status": "ok"}

        config = uvicorn.Config(app, host=host, port=port, log_level="info")
        server = uvicorn.Server(config)
        await server.serve()


def main():
    logging.basicConfig(level=logging.INFO)
    runtime = AIRuntime()

    loop = asyncio.new_event_loop()
    asyncio.set_event_loop(loop)

    async def start():
        await asyncio.gather(
            runtime.run_dbus(),
            runtime.run_http(),
        )

    loop.run_until_complete(start())


if __name__ == "__main__":
    main()
