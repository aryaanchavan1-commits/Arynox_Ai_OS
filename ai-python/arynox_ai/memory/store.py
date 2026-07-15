"""Conversation memory store using SQLite"""

import json
import sqlite3
import time
from pathlib import Path
from typing import Optional
from uuid import uuid4


class MemoryStore:
    def __init__(self, db_path: str = "/var/lib/arynox/ai/memory.db"):
        self.db_path = db_path
        Path(db_path).parent.mkdir(parents=True, exist_ok=True)
        self._init_db()

    def _init_db(self):
        with sqlite3.connect(self.db_path) as conn:
            conn.execute("""
                CREATE TABLE IF NOT EXISTS conversations (
                    id TEXT PRIMARY KEY,
                    provider TEXT NOT NULL,
                    model TEXT NOT NULL,
                    messages TEXT NOT NULL,
                    response TEXT NOT NULL,
                    created_at REAL NOT NULL,
                    tokens_used INTEGER DEFAULT 0
                )
            """)
            conn.execute("""
                CREATE INDEX IF NOT EXISTS idx_conversations_created
                ON conversations(created_at DESC)
            """)
            conn.commit()

    async def store_conversation(self, provider: str, model: str, messages: list, response: dict):
        with sqlite3.connect(self.db_path) as conn:
            conn.execute(
                "INSERT INTO conversations (id, provider, model, messages, response, created_at, tokens_used) VALUES (?, ?, ?, ?, ?, ?, ?)",
                (
                    str(uuid4()),
                    provider,
                    model,
                    json.dumps(messages),
                    json.dumps(response),
                    time.time(),
                    response.get("usage", {}).get("total_tokens", 0),
                ),
            )
            conn.commit()

    async def get_recent(self, limit: int = 50) -> list[dict]:
        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.execute(
                "SELECT * FROM conversations ORDER BY created_at DESC LIMIT ?",
                (limit,),
            )
            results = []
            for row in cursor.fetchall():
                results.append({
                    "id": row[0],
                    "provider": row[1],
                    "model": row[2],
                    "messages": json.loads(row[3]),
                    "response": json.loads(row[4]),
                    "created_at": row[5],
                    "tokens_used": row[6],
                })
            return results

    async def clear(self):
        with sqlite3.connect(self.db_path) as conn:
            conn.execute("DELETE FROM conversations")
            conn.commit()

    async def get_stats(self) -> dict:
        with sqlite3.connect(self.db_path) as conn:
            total = conn.execute("SELECT COUNT(*) FROM conversations").fetchone()[0]
            tokens = conn.execute("SELECT COALESCE(SUM(tokens_used), 0) FROM conversations").fetchone()[0]
            return {"total_conversations": total, "total_tokens": tokens}
