"""AI Agent core - autonomous task execution with user confirmation"""

import asyncio
import json
import logging
import os
import shutil
import subprocess
from pathlib import Path
from typing import Optional
from uuid import uuid4

logger = logging.getLogger("arynox.ai.agent")


class AgentTask:
    def __init__(self, description: str, action: str, params: dict, requires_confirmation: bool = True):
        self.id = str(uuid4())
        self.description = description
        self.action = action
        self.params = params
        self.requires_confirmation = requires_confirmation
        self.confirmed = False
        self.result = None
        self.status = "pending"  # pending | confirmed | running | completed | failed | denied

    def to_dict(self):
        return {
            "id": self.id,
            "description": self.description,
            "action": self.action,
            "params": self.params,
            "status": self.status,
            "result": str(self.result) if self.result else None,
        }


class AIAgent:
    def __init__(self):
        self.tasks: dict[str, AgentTask] = {}
        self._pending_confirmations: list[AgentTask] = []

    async def search_files(self, query: str, path: str = os.path.expanduser("~")) -> list[dict]:
        """Search files by name or content."""
        results = []
        path_obj = Path(path)
        if not path_obj.exists():
            return []

        # Use `find` / `fd` for fast file search
        try:
            result = subprocess.run(
                ["fd", query, path],
                capture_output=True, text=True, timeout=10
            )
            if result.returncode == 0:
                for line in result.stdout.strip().split("\n"):
                    if line:
                        fp = Path(line)
                        results.append({
                            "path": str(fp),
                            "name": fp.name,
                            "size": fp.stat().st_size if fp.exists() else 0,
                        })
        except (subprocess.TimeoutExpired, FileNotFoundError):
            # Fallback to Python os.walk
            for root, dirs, files in os.walk(path):
                for f in files:
                    if query.lower() in f.lower():
                        fp = Path(root) / f
                        results.append({
                            "path": str(fp),
                            "name": f,
                            "size": fp.stat().st_size,
                        })
                    if len(results) >= 50:
                        break
                if len(results) >= 50:
                    break
        return results

    async def organize_files(self, directory: str, pattern: str = "type") -> AgentTask:
        """Organize files by type/extension into folders."""
        task = AgentTask(
            description=f"Organize files in {directory} by {pattern}",
            action="organize_files",
            params={"directory": directory, "pattern": pattern},
        )
        self.tasks[task.id] = task
        self._pending_confirmations.append(task)
        return task

    async def rename_files(self, directory: str, pattern: str, replacement: str) -> AgentTask:
        task = AgentTask(
            description=f"Rename files matching '{pattern}' to '{replacement}' in {directory}",
            action="rename_files",
            params={"directory": directory, "pattern": pattern, "replacement": replacement},
        )
        self.tasks[task.id] = task
        self._pending_confirmations.append(task)
        return task

    async def delete_files(self, paths: list[str]) -> AgentTask:
        task = AgentTask(
            description=f"Delete {len(paths)} files",
            action="delete_files",
            params={"paths": paths},
        )
        self.tasks[task.id] = task
        self._pending_confirmations.append(task)
        return task

    async def install_application(self, package_name: str) -> AgentTask:
        task = AgentTask(
            description=f"Install application: {package_name}",
            action="install_application",
            params={"package": package_name},
        )
        self.tasks[task.id] = task
        self._pending_confirmations.append(task)
        return task

    async def run_command(self, command: str) -> AgentTask:
        task = AgentTask(
            description=f"Run command: {command}",
            action="run_command",
            params={"command": command},
        )
        self.tasks[task.id] = task
        self._pending_confirmations.append(task)
        return task

    async def confirm_task(self, task_id: str, confirmed: bool) -> Optional[dict]:
        task = self.tasks.get(task_id)
        if not task:
            return None

        if not confirmed:
            task.status = "denied"
            return task.to_dict()

        task.confirmed = True
        task.status = "running"

        try:
            result = await self._execute_task(task)
            task.result = result
            task.status = "completed"
        except Exception as e:
            task.result = str(e)
            task.status = "failed"

        return task.to_dict()

    async def _execute_task(self, task: AgentTask) -> str:
        if task.action == "organize_files":
            return await self._do_organize(task.params)
        elif task.action == "rename_files":
            return await self._do_rename(task.params)
        elif task.action == "delete_files":
            return await self._do_delete(task.params)
        elif task.action == "install_application":
            return await self._do_install(task.params)
        elif task.action == "run_command":
            return await self._do_run_command(task.params)
        return "Unknown action"

    async def _do_organize(self, params: dict) -> str:
        directory = Path(params["directory"])
        if not directory.exists():
            raise FileNotFoundError(f"Directory not found: {directory}")

        moved = 0
        for f in directory.iterdir():
            if f.is_file():
                ext = f.suffix[1:] if f.suffix else "no_extension"
                target_dir = directory / ext
                target_dir.mkdir(exist_ok=True)
                shutil.move(str(f), str(target_dir / f.name))
                moved += 1
        return f"Organized {moved} files by extension in {directory}"

    async def _do_rename(self, params: dict) -> str:
        directory = Path(params["directory"])
        pattern = params["pattern"]
        replacement = params["replacement"]

        renamed = 0
        for f in directory.iterdir():
            if f.is_file() and pattern in f.stem:
                new_name = f.stem.replace(pattern, replacement) + f.suffix
                f.rename(directory / new_name)
                renamed += 1
        return f"Renamed {renamed} files"

    async def _do_delete(self, params: dict) -> str:
        paths = params["paths"]
        deleted = 0
        for p in paths:
            path = Path(p)
            if path.exists():
                if path.is_file():
                    path.unlink()
                elif path.is_dir():
                    shutil.rmtree(path)
                deleted += 1
        return f"Deleted {deleted} items"

    async def _do_install(self, params: dict) -> str:
        package = params["package"]
        result = subprocess.run(
            ["apt-get", "install", "-y", package],
            capture_output=True, text=True, timeout=300
        )
        if result.returncode == 0:
            return f"Successfully installed {package}"
        raise RuntimeError(f"Installation failed: {result.stderr}")

    async def _do_run_command(self, params: dict) -> str:
        command = params["command"]
        result = subprocess.run(
            command, shell=True, capture_output=True, text=True, timeout=60
        )
        output = result.stdout or result.stderr
        return f"Exit code: {result.returncode}\n{output[:500]}"

    def get_pending_confirmations(self) -> list[dict]:
        return [t.to_dict() for t in self._pending_confirmations]

    def get_task(self, task_id: str) -> Optional[dict]:
        task = self.tasks.get(task_id)
        return task.to_dict() if task else None
