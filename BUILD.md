# Build and validation record

## Release matrix

| Release | Build host GPU | Target | Source commit | Wheel SHA-256 |
|---|---|---|---|---|
| v1.1.0 | NVIDIA GeForce RTX 4090 | `sm_89` | `302e0e97024ebd68688fe890e5df83731edf7b54` | `b29d74fca0b6021bc80714e679c93278ce35ed57dfac657ff0bbb7d3a146ef91` |
| v1.0.0 | NVIDIA RTX 50-series | `sm_120a` | `302e0e97024ebd68688fe890e5df83731edf7b54` | `11b943c88a86bf926f7127b499021cd3a0e193a1d6c77203367e0cbdd83e2c5d` |

Both builds use:

- Linux x86_64
- Python 3.12.3
- PyTorch 2.14.0+cu130
- CUDA toolkit 13.0 (`nvidia-cuda-nvcc==13.0.88`, `nvidia-cuda-cccl==13.0.85`, `nvidia-nvvm==13.0.88`)
- Nunchaku upstream commit `302e0e97024ebd68688fe890e5df83731edf7b54`

## RTX 4090 / `sm_89` build (v1.1.0)

The source was cloned into a new build directory to prevent the existing `sm_120a` object files from being reused. The build ran on a physical RTX 4090 with compute capability 8.9.

```bash
export CUDA_HOME=/path/to/ComfyUI/venv/lib/python3.12/site-packages/nvidia/cu13
export PATH=/path/to/ComfyUI/venv/bin:$CUDA_HOME/bin:$PATH
export LD_LIBRARY_PATH=$CUDA_HOME/lib:${LD_LIBRARY_PATH:-}
export LIBRARY_PATH=$CUDA_HOME/lib:${LIBRARY_PATH:-}
export NUNCHAKU_INSTALL_MODE=FAST
export NUNCHAKU_BUILD_WHEELS=1
export MAX_JOBS=16

python setup.py bdist_wheel
```

Nunchaku reported:

```text
Found nvcc version: 13.0.88
Detected SM targets: ['89']
```

Every CUDA compile command contained:

```text
-gencode arch=compute_89,code=sm_89
```

Wheel:

```text
nunchaku-1.3.0.dev20260914+cu13.0torch2.14-cp312-cp312-linux_x86_64.whl
SHA-256: b29d74fca0b6021bc80714e679c93278ce35ed57dfac657ff0bbb7d3a146ef91
```

### Runtime validation

The wheel was force-installed with `--no-deps`, imported against PyTorch 2.14.0+cu130, and tested on the RTX 4090. The AWQ GEMV kernel was executed for `(m, n, k) = (1, 128, 4096)` and `(4, 256, 4096)`, followed by `torch.cuda.synchronize()` for each call.

Result:

```text
AWQ kernel OK: m=1 n=128 k=4096 shape=(1, 128) dtype=torch.float16
AWQ kernel OK: m=4 n=256 k=4096 shape=(4, 256) dtype=torch.float16
RTX 4090 sm_89 validation PASSED
```

This directly covers the earlier failure in `src/kernels/awq/gemv_awq.cu`:

```text
CUDA error: no kernel image is available for execution on the device
```

## RTX 5090 / `sm_120a` build (v1.0.0)

The original v1.0.0 binary remains unchanged. It was built with `NUNCHAKU_INSTALL_MODE=FAST` on an RTX 50-series GPU, resulting in an `sm_120a`-specific extension.

Do not install the v1.0.0 binary on an RTX 4090. Its wheel SHA-256 remains:

```text
11b943c88a86bf926f7127b499021cd3a0e193a1d6c77203367e0cbdd83e2c5d
```

## Publication

The exact `+cu13.0torch2.14` RTX 4090 wheel is mirrored at:

```text
https://huggingface.co/IrisLan/nunchaku-prebuilt-torch2.14-cu130/tree/main/rtx4090-sm89
```

GitHub normalizes `+` in Release asset filenames, producing a filename that pip rejects. Therefore, v1.1.0 publishes a `.tar.gz` bundle containing the correctly named wheel and an accompanying `SHA256SUMS` file. The v1.0.0 instructions preserve its original asset and download it into a corrected local filename.

