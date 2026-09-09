#!/usr/bin/env bash
# Install this prebuilt nunchaku wheel into a ComfyUI venv.
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 /path/to/ComfyUI [wheel.whl]"
  exit 1
fi

COMFYUI_ROOT="$(cd "$1" && pwd)"
PY="${COMFYUI_ROOT}/venv/bin/python"
if [[ ! -x "$PY" ]]; then
  echo "ComfyUI venv python not found: $PY"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WHEEL="${2:-}"
if [[ -z "$WHEEL" ]]; then
  WHEEL="$(ls -1 "${SCRIPT_DIR}/../dist"/nunchaku-*-cp312-cp312-linux_x86_64.whl | head -n 1)"
fi
if [[ ! -f "$WHEEL" ]]; then
  echo "Wheel not found. Download it from GitHub Releases into dist/, or pass the .whl path."
  exit 1
fi

echo "Using python: $PY"
"$PY" - <<'PY'
import sys, torch
print("python", sys.version.split()[0])
print("torch", torch.__version__, "cuda", torch.version.cuda)
if not sys.version.startswith("3.12"):
    raise SystemExit("This wheel is for Python 3.12 only.")
if not torch.__version__.startswith("2.14"):
    print("WARNING: this wheel was compiled against PyTorch 2.14.0+cu130; other torch versions may fail with undefined symbol errors.")
if str(torch.version.cuda) != "13.0":
    print("WARNING: this wheel was compiled against CUDA 13.0 (cu130).")
PY

"$PY" -m pip install --upgrade --force-reinstall "$WHEEL"
"$PY" -c "from nunchaku import NunchakuFluxTransformer2dModel; import importlib.metadata as m; print('installed', m.version('nunchaku'))"
echo "Done. Restart ComfyUI, and use ComfyUI-nunchaku >= 1.2.1."
