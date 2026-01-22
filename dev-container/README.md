# dev-container: O3DE Development Container

## Purpose

This directory provides a **hardware-agnostic development container** for O3DE (Open 3D Engine). Unlike the main repo's `/Docker/` which builds SDK packages from a cloned source, this solution:

1. **Mounts your local source code** - work with your own directories, not a clone
2. **Supports multiple GPU vendors** - NVIDIA, AMD, and Intel (not just NVIDIA)
3. **Simplifies developer workflow** - docker-compose for easy startup
4. **Enables both building AND running** O3DE in the container

## Current State (as of 2026-01)

- Full build toolchain (GCC 13, Clang, CMake 3.28.3, Ninja)
- GPU auto-detection via `lspci` (NVIDIA/AMD/Intel)
- Docker Compose profiles for vendor-specific GPU passthrough
- `run-container.sh` - Single-command startup with auto-detection
- `build-engine.sh` - Automated engine build script
- Confirmed working: AMD GPU runtime, NVIDIA GPU runtime
- Needs testing: Intel integrated graphics

## Vendor Neutrality Assessment

### What IS vendor-neutral:
| Component | Status | Notes |
|-----------|--------|-------|
| Base image | Neutral | `ubuntu:22.04`, no vendor lock-in |
| GPU detection | Neutral | `entrypoint.sh` auto-detects via `lspci` |
| Graphics libs | Neutral | Vulkan, Mesa - work with any GPU |
| Build toolchain | Neutral | Standard GCC/Clang, no GPU-specific compilers |

### Vendor-neutral implementation:
| Component | Approach |
|-----------|----------|
| docker-compose.yml | YAML anchors for shared config + profiles (`nvidia`, `amd`, `intel`) |
| run-container.sh | Auto-detects GPU via `lspci`, selects correct profile |
| Manual override | `./run-container.sh --profile nvidia` to force a specific vendor |

### Remaining limitations:
| Component | Issue |
|-----------|-------|
| Architecture | x86_64 only (CMake binary hardcoded) |
| Display server | X11 only (no Wayland support yet) |

### GPU Vendor Requirements:
| Vendor | Host Requirements | Container Devices | Env Vars |
|--------|-------------------|-------------------|----------|
| NVIDIA | nvidia-container-toolkit | (handled by runtime) | `NVIDIA_VISIBLE_DEVICES=all` |
| AMD | ROCm kernel driver | `/dev/kfd`, `/dev/dri` | `ROC_ENABLE_PRE_VEGA=1` (optional) |
| Intel | i915 driver | `/dev/dri` | (none required) |

## Goals

1. **Single-command startup** regardless of GPU vendor
2. **Zero host modification** beyond Docker and GPU drivers
3. **Seamless file permissions** via UID/GID mapping
4. **GUI application support** (Project Manager, Editor) via X11
5. **Cross-architecture** support (x86_64, ARM64 stretch goal)

## Architecture

```
Host System
├── GPU Driver (NVIDIA/AMD/Intel)
├── Docker Engine
│   └── nvidia-container-toolkit (if NVIDIA)
└── /home/user/o3de_dev/  ← Your source code
        │
        ▼ (bind mount)
Container
├── Ubuntu 22.04 base
├── Build toolchain (GCC, Clang, CMake, Ninja)
├── O3DE dependencies (Qt libs, Vulkan, etc.)
├── /home/devuser/o3de/  ← Mounted source
└── entrypoint.sh (GPU detection, user setup)
```

## Prerequisites

| GPU Vendor | Host Requirements |
|------------|-------------------|
| NVIDIA | `nvidia-driver-xxx`, `nvidia-container-toolkit` |
| AMD | AMDGPU driver (usually included in kernel), `/dev/kfd` and `/dev/dri` accessible |
| Intel | i915 driver (included in kernel), `/dev/dri` accessible |

All vendors require:
- Docker Engine
- User in `docker` group (`sudo usermod -aG docker $USER`, then logout/login)

## Usage

```bash
# From dev-container directory
cd dev-container

# Auto-detect GPU and launch container
./run-container.sh

# Or manually specify GPU vendor
./run-container.sh --profile nvidia
./run-container.sh --profile amd
./run-container.sh --profile intel

# Inside container
./dev-container/build-engine.sh    # Build the engine
./build/linux/bin/profile/Editor   # Run the editor (once built)
```

### First-time setup

```bash
# Build the container image (only needed once, or after Dockerfile changes)
docker compose --profile nvidia build   # or amd/intel
```

## Comparison with Main Repo /Docker/

| Feature | dev-container (this) | /Docker/ (main repo) |
|---------|----------------------|---------------------|
| Source code | Mounted from host | Cloned at build time |
| GPU support | NVIDIA + AMD + Intel | NVIDIA only |
| Output | Development environment | SDK installer package |
| Startup | docker-compose | Manual docker run |
| Use case | Iterative development | Release packaging |

## Known Issues / TODO

- [x] Unify docker-compose.yml for all GPU vendors (use profiles or detection script)
- [x] Test NVIDIA runtime path end-to-end
- [x] Document host prerequisites per GPU vendor
- [ ] Test Intel integrated graphics
- [ ] Add ARM64 support (would need different CMake install)
- [ ] Consider Wayland support (currently X11 only)
- [ ] Add VS Code devcontainer.json for IDE integration

## Files Reference

| File | Purpose |
|------|---------|
| `Dockerfile.dev` | Container image definition (Ubuntu 22.04 + build tools) |
| `docker-compose.yml` | Service orchestration with GPU vendor profiles |
| `entrypoint.sh` | Container init (GPU detection, env setup) |
| `run-container.sh` | Main entry point - auto-detects GPU, manages X11 access |
| `build-engine.sh` | O3DE build automation |
| `.env` | Default UID/GID values (optional, run-container.sh auto-detects) |

## Session Notes

_Use this section to track progress across work sessions._

### 2025-05: Initial development
- Created initial container setup
- Achieved functional Linux build in container
- Achieved functional runtime on AMD GPU
- Renamed to dev-container (on feature branch)
- Paused development

### 2026-01: Resuming development
- Merged upstream changes
- Assessed vendor neutrality gaps
- Implemented Docker Compose profiles for NVIDIA/AMD/Intel
- Added GPU auto-detection to `run-container.sh`
- Tested and confirmed NVIDIA GPU passthrough working (RTX 4070)
- Simplified `entrypoint.sh` (removed usermod, compose handles groups)
