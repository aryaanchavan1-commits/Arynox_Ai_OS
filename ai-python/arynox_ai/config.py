"""Runtime configuration management"""

import yaml
import json
import os
from pathlib import Path
from typing import Optional
from pydantic import BaseModel
from cryptography.fernet import Fernet


class ProviderConfig(BaseModel):
    api_key: str = ""
    base_url: str = ""
    default_model: str = ""
    temperature: float = 0.7
    max_tokens: int = 4096


class RuntimeConfig:
    def __init__(self):
        self.db_path: str = "/var/lib/arynox/ai/memory.db"
        self.providers: dict[str, ProviderConfig] = {}
        self.encryption_key: Optional[bytes] = None

    @classmethod
    def load(cls, path: str = "/etc/arynox/ai-runtime.yaml") -> "RuntimeConfig":
        config = cls()

        # Load encryption key
        key_path = Path("/etc/arynox/ai/encryption.key")
        if key_path.exists():
            config.encryption_key = key_path.read_bytes()

        # Load provider configs from YAML
        config_path = Path(path)
        if config_path.exists():
            with open(config_path) as f:
                data = yaml.safe_load(f) or {}

            for name, cfg in data.get("providers", {}).items():
                api_key = cfg.get("api_key", "")
                # Decrypt key if encrypted
                if config.encryption_key and api_key.startswith("enc:"):
                    try:
                        fernet = Fernet(config.encryption_key)
                        api_key = fernet.decrypt(api_key[4:].encode()).decode()
                    except Exception:
                        api_key = ""

                config.providers[name] = ProviderConfig(
                    api_key=api_key,
                    base_url=cfg.get("base_url", ""),
                    default_model=cfg.get("default_model", ""),
                    temperature=cfg.get("temperature", 0.7),
                    max_tokens=cfg.get("max_tokens", 4096),
                )

        return config

    def get_provider(self, name: str) -> Optional[ProviderConfig]:
        return self.providers.get(name)

    @staticmethod
    def encrypt_api_key(key: str, encryption_key: bytes) -> str:
        fernet = Fernet(encryption_key)
        return f"enc:{fernet.encrypt(key.encode()).decode()}"
