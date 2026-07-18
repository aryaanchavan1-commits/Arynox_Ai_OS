from setuptools import setup, find_packages

setup(
    name="arynox-ai-runtime",
    version="0.1.0",
    description="Arynox OS - AI Runtime Daemon",
    author="Arynox Technologies",
    packages=find_packages(include=["arynox_ai", "arynox_ai.*"]),
    python_requires=">=3.11",
    install_requires=[
        "httpx",
        "pydantic",
        "pyyaml",
    ],
    entry_points={
        "console_scripts": [
            "arynox-ai-runtime=arynox_ai.main:main",
        ],
    },
)
