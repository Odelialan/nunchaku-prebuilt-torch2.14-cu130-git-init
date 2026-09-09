# nunchaku prebuilt wheel — PyTorch 2.14 + CUDA 13.0 + Linux cp312

**Author:** OdeliaLan  
**Repo version:** `v1.0.0` (2026-09-09)  
**GitHub:** https://github.com/Odelialan/nunchaku-prebuilt-torch2.14-cu130-git-init

Prebuilt **[nunchaku](https://github.com/nunchaku-ai/nunchaku)** binary for this environment:

| Item | Value |
|---|---|
| OS | Linux x86_64 |
| Python | 3.12 (`cp312`) |
| PyTorch | **2.14.0+cu130** |
| CUDA | **13.0** |
| GPU | NVIDIA RTX 50-series (`sm_120` / `sm_120a`), e.g. RTX 5090 |

Official Hugging Face / GitHub wheels currently stop around Torch 2.11. Installing those on Torch 2.14 fails with:

```text
ImportError: .../nunchaku/_C.cpython-312-x86_64-linux-gnu.so: undefined symbol: _ZN3c104impl3cow23materialize_cow_storageERNS_11StorageImplE
```

This project redistributes nunchaku `1.3.0dev` compiled against Torch 2.14 + CUDA 13 + `sm_120a`.

The `.whl` is ~118 MB (uncompressed `_C.so` ~212 MB). It is **not** stored in git. Download it from **[Releases](https://github.com/Odelialan/nunchaku-prebuilt-torch2.14-cu130-git-init/releases)**.

## Install (ComfyUI venv)

Download `nunchaku-1.3.0.dev20260909+cu13.0torch2.14-cp312-cp312-linux_x86_64.whl` from Releases, then:

```bash
# use ComfyUI's venv, not system python
/path/to/ComfyUI/venv/bin/python -m pip install --force-reinstall \
  ./nunchaku-1.3.0.dev20260909+cu13.0torch2.14-cp312-cp312-linux_x86_64.whl
```

Or:

```bash
bash scripts/install_comfyui.sh /path/to/ComfyUI /path/to/the.whl
```

Then install **ComfyUI-nunchaku ≥ 1.2.1** into `custom_nodes`, restart ComfyUI, and confirm the log shows `Nunchaku version: 1.3.0.dev20260909` with no `undefined symbol`.

Check the environment first:

```bash
/path/to/ComfyUI/venv/bin/python -c "import sys,torch; print(sys.version); print(torch.__version__, torch.version.cuda)"
```

Do **not** use this wheel if Python is not 3.12, or Torch is not 2.14 + cu130.

## Changelog

### v1.0.0 — 2026-09-09

- First public prebuilt wheel for Linux + Python 3.12 + PyTorch 2.14.0+cu130 + CUDA 13.0 + RTX 50-series (`sm_120a`).
- Fixes ComfyUI-nunchaku startup `undefined symbol: materialize_cow_storage` caused by official wheels built for older Torch.
- Adds `scripts/install_comfyui.sh` for installing into a ComfyUI venv.
- Adds `scripts/pack_wheel.py` to re-pack from an already-compiled local `nunchaku` package (`NUNCHAKU_PKG=...`).
- Wheel is published on GitHub Releases, not in git, because it exceeds the 100 MB git file limit.

## License

Nunchaku is **Apache-2.0**. See `LICENSE` and [nunchaku-ai/nunchaku](https://github.com/nunchaku-ai/nunchaku). This repository only redistributes a binary build for a specific PyTorch/CUDA combo.
