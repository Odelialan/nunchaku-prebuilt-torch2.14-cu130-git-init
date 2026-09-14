# Nunchaku prebuilt wheels — PyTorch 2.14 + CUDA 13.0 + Linux cp312

**Author:** OdeliaLan  
**Repository:** https://github.com/Odelialan/nunchaku-prebuilt-torch2.14-cu130-git-init

Prebuilt [Nunchaku](https://github.com/nunchaku-ai/nunchaku) binaries for Linux x86_64, Python 3.12, PyTorch 2.14.0+cu130, and CUDA 13.0.

## Choose the build that matches your GPU

| Release | GPU | CUDA kernel target | Nunchaku package | Validation |
|---|---|---|---|---|
| [v1.1.0](https://github.com/Odelialan/nunchaku-prebuilt-torch2.14-cu130-git-init/releases/tag/v1.1.0) | RTX 4090 | `sm_89` | `1.3.0.dev20260914+cu13.0torch2.14` | AWQ GEMV executed on a physical RTX 4090 |
| [v1.0.0](https://github.com/Odelialan/nunchaku-prebuilt-torch2.14-cu130-git-init/releases/tag/v1.0.0) | RTX 50-series, e.g. RTX 5090 | `sm_120a` | `1.3.0.dev20260909+cu13.0torch2.14` | Original 5090 build, unchanged |

These wheels are architecture-specific. The 5090 `sm_120a` wheel produces `CUDA error: no kernel image is available for execution on the device` on an RTX 4090. The 4090 `sm_89` wheel is not intended for an RTX 5090.

## RTX 4090 (`sm_89`) — v1.1.0

The recommended GitHub Release asset is a `.tar.gz` bundle so the valid `+cu13.0torch2.14` wheel filename is preserved. Extract it, then install the contained wheel:

```bash
tar -xzf nunchaku-rtx4090-sm89-torch2.14-cu130-cp312.tar.gz
/path/to/ComfyUI/venv/bin/python -m pip install \
  --force-reinstall --no-deps \
  './nunchaku-1.3.0.dev20260914+cu13.0torch2.14-cp312-cp312-linux_x86_64.whl'
```

The exact wheel is also mirrored on [Hugging Face](https://huggingface.co/IrisLan/nunchaku-prebuilt-torch2.14-cu130/tree/main/rtx4090-sm89). It can be downloaded without renaming:

```bash
WHEEL_NAME='nunchaku-1.3.0.dev20260914+cu13.0torch2.14-cp312-cp312-linux_x86_64.whl'
curl -fL --retry 5 \
  -o "$WHEEL_NAME" \
  'https://huggingface.co/IrisLan/nunchaku-prebuilt-torch2.14-cu130/resolve/main/rtx4090-sm89/nunchaku-1.3.0.dev20260914%2Bcu13.0torch2.14-cp312-cp312-linux_x86_64.whl?download=true'
echo 'b29d74fca0b6021bc80714e679c93278ce35ed57dfac657ff0bbb7d3a146ef91  nunchaku-1.3.0.dev20260914+cu13.0torch2.14-cp312-cp312-linux_x86_64.whl' | sha256sum -c -
/path/to/ComfyUI/venv/bin/python -m pip install --force-reinstall --no-deps "./$WHEEL_NAME"
```

Restart ComfyUI after installation. To verify the exact CUDA path that previously failed:

```bash
/path/to/ComfyUI/venv/bin/python - <<'PY'
import torch
from nunchaku.ops.gemv import awq_gemv_w4a16_cuda

assert torch.cuda.get_device_capability(0) == (8, 9)
m, n, k, group_size = 1, 128, 4096, 64
x = torch.randn(m, k, device="cuda", dtype=torch.float16)
qweight = torch.zeros(n // 4, k // 2, device="cuda", dtype=torch.int32)
scales = torch.ones(k // group_size, n, device="cuda", dtype=torch.float16)
zeros = torch.zeros(k // group_size, n, device="cuda", dtype=torch.float16)
y = awq_gemv_w4a16_cuda(x, qweight, scales, zeros, m, n, k, group_size)
torch.cuda.synchronize()
print("RTX 4090 AWQ kernel OK:", y.shape)
PY
```

## RTX 5090 / RTX 50-series (`sm_120a`) — v1.0.0

The original [v1.0.0 release](https://github.com/Odelialan/nunchaku-prebuilt-torch2.14-cu130-git-init/releases/tag/v1.0.0) and its binary have not been changed.

GitHub sanitized the `+` in the v1.0.0 asset name to a dot. Download it while assigning a valid wheel filename:

```bash
curl -fL --retry 5 \
  -o 'nunchaku-1.3.0.dev20260909+cu13.0torch2.14-cp312-cp312-linux_x86_64.whl' \
  'https://github.com/Odelialan/nunchaku-prebuilt-torch2.14-cu130-git-init/releases/download/v1.0.0/nunchaku-1.3.0.dev20260909.cu13.0torch2.14-cp312-cp312-linux_x86_64.whl'
/path/to/ComfyUI/venv/bin/python -m pip install \
  --force-reinstall --no-deps \
  './nunchaku-1.3.0.dev20260909+cu13.0torch2.14-cp312-cp312-linux_x86_64.whl'
```

## Compatibility

Check the environment before installing:

```bash
/path/to/ComfyUI/venv/bin/python -c 'import sys, torch; print(sys.version); print(torch.__version__, torch.version.cuda); print(torch.cuda.get_device_name(0), torch.cuda.get_device_capability(0))'
```

Use these builds only with:

- Linux x86_64
- Python 3.12 (`cp312`)
- PyTorch 2.14.x built for CUDA 13.0 (`cu130`)
- The GPU architecture listed for the selected release

`--no-deps` is intentional: it prevents pip from replacing the working ComfyUI PyTorch/CUDA stack.

## Checksums

See [`SHA256SUMS`](SHA256SUMS). The v1.1.0 Release also contains a checksum file covering its downloadable bundle and the wheel inside it.

## Changelog

### v1.1.0 — 2026-09-14

- Added a separate RTX 4090 build compiled only for `sm_89`.
- Verified the previously failing `awq_gemv_w4a16_cuda` kernel on a physical RTX 4090 with CUDA synchronization enabled.
- Preserved v1.0.0 and the original RTX 5090 `sm_120a` asset unchanged.
- Added architecture-aware installation checks and `--no-deps` installation.

### v1.0.0 — 2026-09-09

- First public build for RTX 50-series (`sm_120a`).
- Built against Python 3.12, PyTorch 2.14.0+cu130, and CUDA 13.0.

## License

Nunchaku is Apache-2.0. See [`LICENSE`](LICENSE) and the [upstream project](https://github.com/nunchaku-ai/nunchaku).

