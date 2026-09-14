#!/usr/bin/env bash
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
CAPABILITY="$($PY -c 'import torch; print(".".join(map(str, torch.cuda.get_device_capability(0))))')"
WHEEL="${2:-}"

if [[ -z "$WHEEL" ]]; then
  case "$CAPABILITY" in
    8.9)
      WHEEL="$(find "${SCRIPT_DIR}/../dist" -maxdepth 1 -type f -name 'nunchaku-*20260914*.whl' | sort -V | tail -n 1)"
      ;;
    12.0)
      WHEEL="$(find "${SCRIPT_DIR}/../dist" -maxdepth 1 -type f -name 'nunchaku-*20260909*.whl' | sort -V | tail -n 1)"
      ;;
    *)
      echo "No bundled wheel is registered for CUDA capability ${CAPABILITY}. Pass an explicit compatible wheel."
      exit 1
      ;;
  esac
fi

if [[ ! -f "$WHEEL" ]]; then
  echo "Wheel not found: $WHEEL"
  exit 1
fi

case "$(basename "$WHEEL")" in
  *20260914*) EXPECTED_CAPABILITY="8.9" ;;
  *20260909*) EXPECTED_CAPABILITY="12.0" ;;
  *) EXPECTED_CAPABILITY="" ;;
esac

if [[ -n "$EXPECTED_CAPABILITY" && "$CAPABILITY" != "$EXPECTED_CAPABILITY" ]]; then
  echo "GPU mismatch: this wheel expects capability ${EXPECTED_CAPABILITY}, but the current GPU is ${CAPABILITY}."
  exit 1
fi

TEMP_WHEEL_DIR=""
WHEEL_BASENAME="$(basename "$WHEEL")"
if [[ "$WHEEL_BASENAME" == *.cu13.0torch2.14-* && "$WHEEL_BASENAME" != *+cu13.0torch2.14-* ]]; then
  TEMP_WHEEL_DIR="$(mktemp -d)"
  trap 'test -n "$TEMP_WHEEL_DIR" && rm -rf -- "$TEMP_WHEEL_DIR"' EXIT
  VALID_BASENAME="${WHEEL_BASENAME/.cu13.0torch2.14-/+cu13.0torch2.14-}"
  cp -- "$WHEEL" "$TEMP_WHEEL_DIR/$VALID_BASENAME"
  WHEEL="$TEMP_WHEEL_DIR/$VALID_BASENAME"
fi

"$PY" - <<'PY'
import sys
import torch

print("python", sys.version.split()[0])
print("torch", torch.__version__, "cuda", torch.version.cuda)
print("gpu", torch.cuda.get_device_name(0), torch.cuda.get_device_capability(0))
if not sys.version.startswith("3.12"):
    raise SystemExit("This wheel requires Python 3.12.")
if not torch.__version__.startswith("2.14"):
    raise SystemExit("This wheel requires PyTorch 2.14.x.")
if str(torch.version.cuda) != "13.0":
    raise SystemExit("This wheel requires a cu130 PyTorch build.")
PY

"$PY" -m pip install --force-reinstall --no-deps "$WHEEL"

"$PY" - <<'PY'
import importlib.metadata as metadata
import torch

print("installed nunchaku", metadata.version("nunchaku"))
if torch.cuda.get_device_capability(0) == (8, 9):
    from nunchaku.ops.gemv import awq_gemv_w4a16_cuda

    m, n, k, group_size = 1, 128, 4096, 64
    x = torch.randn(m, k, device="cuda", dtype=torch.float16)
    qweight = torch.zeros(n // 4, k // 2, device="cuda", dtype=torch.int32)
    scales = torch.ones(k // group_size, n, device="cuda", dtype=torch.float16)
    zeros = torch.zeros(k // group_size, n, device="cuda", dtype=torch.float16)
    y = awq_gemv_w4a16_cuda(x, qweight, scales, zeros, m, n, k, group_size)
    torch.cuda.synchronize()
    print("RTX 4090 AWQ kernel OK:", tuple(y.shape))
PY

echo "Done. Restart ComfyUI before running a workflow."

