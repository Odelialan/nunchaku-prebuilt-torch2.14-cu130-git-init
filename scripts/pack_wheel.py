#!/usr/bin/env python3
"""Pack the already-compiled nunchaku package into a binary wheel."""

from __future__ import annotations

import base64
import hashlib
import os
import zipfile
from pathlib import Path

VERSION = "1.3.0.dev20260909+cu13.0torch2.14"
TAG = "cp312-cp312-linux_x86_64"
WHEEL_NAME = f"nunchaku-{VERSION}-{TAG}.whl"

ROOT = Path(__file__).resolve().parents[1]
SRC = Path(os.environ.get("NUNCHAKU_PKG", "")).expanduser() if os.environ.get("NUNCHAKU_PKG") else None
LICENSE = ROOT / "LICENSE"
OUT_DIR = ROOT / "dist"


def skip(path: Path) -> bool:
    parts = set(path.parts)
    if "__pycache__" in parts:
        return True
    return path.suffix in {".pyc", ".pyo"}


def sha256_b64(data: bytes) -> str:
    digest = hashlib.sha256(data).digest()
    return "sha256=" + base64.urlsafe_b64encode(digest).decode().rstrip("=")


def main() -> None:
    src = SRC
    if src is None:
        raise SystemExit("Set NUNCHAKU_PKG to the installed nunchaku package dir, e.g. <ComfyUI>/venv/lib/python3.12/site-packages/nunchaku")
    if not (src / "_C.cpython-312-x86_64-linux-gnu.so").exists():
        raise SystemExit(f"missing compiled extension in {src}")

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    wheel_path = OUT_DIR / WHEEL_NAME
    dist_info = f"nunchaku-{VERSION}.dist-info"

    files: list[tuple[str, bytes]] = []
    for path in src.rglob("*"):
        if not path.is_file() or skip(path):
            continue
        rel = path.relative_to(src).as_posix()
        files.append((f"nunchaku/{rel}", path.read_bytes()))

    files.append((f"{dist_info}/LICENSE", LICENSE.read_bytes()))
    files.append(
        (
            f"{dist_info}/WHEEL",
            "\n".join(
                [
                    "Wheel-Version: 1.0",
                    "Generator: nunchaku-prebuilt-pack 1.0",
                    "Root-Is-Purelib: false",
                    f"Tag: {TAG}",
                    "",
                ]
            ).encode(),
        )
    )
    files.append(
        (
            f"{dist_info}/METADATA",
            "\n".join(
                [
                    "Metadata-Version: 2.1",
                    "Name: nunchaku",
                    f"Version: {VERSION}",
                    "Summary: Prebuilt Nunchaku wheel for PyTorch 2.14 + CUDA 13.0 + Linux cp312 (RTX 50-series / sm_120)",
                    "Home-page: https://github.com/nunchaku-ai/nunchaku",
                    "License: Apache-2.0",
                    "Requires-Python: ==3.12.*",
                    "Classifier: Operating System :: POSIX :: Linux",
                    "Classifier: Programming Language :: Python :: 3.12",
                    "Requires-Dist: accelerate>=1.9",
                    "Requires-Dist: diffusers>=0.36",
                    "Requires-Dist: einops",
                    "Requires-Dist: huggingface-hub>=0.34",
                    "Requires-Dist: peft>=0.17",
                    "Requires-Dist: protobuf",
                    "Requires-Dist: sentencepiece",
                    "Requires-Dist: torchvision>=0.20",
                    "Requires-Dist: transformers>=4.54",
                    "",
                    "Prebuilt binary of nunchaku-ai/nunchaku, compiled against:",
                    "- Python 3.12",
                    "- PyTorch 2.14.0+cu130",
                    "- CUDA 13.0",
                    "- Linux x86_64, GPU arch sm_120a (RTX 50-series)",
                    "",
                ]
            ).encode(),
        )
    )

    record_lines = []
    for name, data in files:
        record_lines.append(f"{name},{sha256_b64(data)},{len(data)}")
    record_lines.append(f"{dist_info}/RECORD,,")
    record_bytes = ("\n".join(record_lines) + "\n").encode()
    files.append((f"{dist_info}/RECORD", record_bytes))

    with zipfile.ZipFile(wheel_path, "w", compression=zipfile.ZIP_DEFLATED) as zf:
        for name, data in files:
            zf.writestr(name, data)

    print(f"wrote {wheel_path} ({wheel_path.stat().st_size / 1024 / 1024:.1f} MB)")


if __name__ == "__main__":
    main()
