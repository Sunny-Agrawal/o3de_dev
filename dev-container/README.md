# dev-container: O3DE Development Container

## Purpose

This directory provides a **hardware-agnostic development container** for O3DE (Open 3D Engine). Unlike the main repo's `/Docker/` which builds SDK packages from a cloned source, this solution:

1. **Mounts your local source code** - work with your own directories, not a clone
2. **Supports multiple GPU vendors** - NVIDIA, AMD, and Intel (not just NVIDIA)
3. **Simplifies developer workflow** - docker-compose for easy startup
4. **Enables both building AND running** O3DE in the container

## Current State (as of 2025-05)

- Full build toolchain (GCC 13, Clang, CMake 3.28.3, Ninja)
- GPU auto-detection in entrypoint.sh (NVIDIA/AMD/Intel)
- `build-engine.sh` - Automated engine build script
- `run-container.sh` - Helper with X11 access management
- `.env` - UID/GID defaults
- Confirmed working: AMD GPU runtime
- Needs testing: NVIDIA GPU runtime

## Vendor Neutrality Assessment

### What IS vendor-neutral:
| Component | Status | Notes |
|-----------|--------|-------|
| Base image | Neutral | `ubuntu:22.04`, no vendor lock-in |
| GPU detection | Neutral | `entrypoint.sh` auto-detects via `lspci` |
| Graphics libs | Neutral | Vulkan, Mesa - work with any GPU |
| Build toolchain | Neutral | Standard GCC/Clang, no GPU-specific compilers |

### What is NOT vendor-neutral:
| Component | Issue | Fix Needed |
|-----------|-------|------------|
| docker-compose.yml | AMD devices hardcoded (`/dev/kfd`, `/dev/dri`) | Need conditional or multiple compose files |
| docker-compose.yml | NVIDIA section commented out | Need unified approach |
| Runtime invocation | Different docker flags per vendor | Need wrapper script or compose profiles |
| Architecture | x86_64 only (CMake binary) | Need ARM64 support |

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

## Usage (target workflow)

```bash
# From dev-container directory
./run-container.sh          # Auto-detects GPU, launches container

# Inside container
./build-engine.sh           # Build the engine
./build/linux/bin/profile/Editor  # Run the editor (once built)
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

- [ ] Unify docker-compose.yml for all GPU vendors (use profiles or detection script)
- [ ] Test NVIDIA runtime path end-to-end
- [ ] Test Intel integrated graphics
- [ ] Add ARM64 support (would need different CMake install)
- [ ] Consider Wayland support (currently X11 only)
- [ ] Add VS Code devcontainer.json for IDE integration
- [ ] Document host prerequisites per GPU vendor

## Files Reference

| File | Purpose |
|------|---------|
| `Dockerfile.dev` | Container image definition |
| `docker-compose.yml` | Service orchestration |
| `entrypoint.sh` | Container init (GPU detect, user setup) |
| `build-engine.sh` | O3DE build automation |
| `run-container.sh` | Container launch with X11 setup |
| `.env` | Default UID/GID values |

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
- Assessing vendor neutrality
- Planning path to true hardware-agnostic solution
