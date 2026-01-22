# dev-container: O3DE Development Container

A hardware-agnostic Docker container for building and running O3DE (Open 3D Engine) on Linux with GPU support for NVIDIA, AMD, and Intel.

---

## Quick Start (Copy-Paste Commands)

### Step 0: One-Time Host Setup

```bash
# Install Docker (if not already installed)
# See: https://docs.docker.com/engine/install/ubuntu/

# Add yourself to the docker group (required for GPU access)
sudo usermod -aG docker $USER

# Log out and log back in (or reboot) for group change to take effect
# Verify with: groups | grep docker
```

**For NVIDIA GPUs only:**
```bash
# Install nvidia-container-toolkit
# See: https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html
sudo apt-get install -y nvidia-container-toolkit
sudo systemctl restart docker
```

### Step 1: Build the Container Image

```bash
# Navigate to the dev-container directory
cd dev-container

# Build the container (auto-detects your GPU)
# For NVIDIA:
docker compose --profile nvidia build

# For AMD:
docker compose --profile amd build

# For Intel:
docker compose --profile intel build
```

This takes ~7 minutes on a fast connection (downloads Ubuntu base + build tools).

### Step 2: Build the O3DE Engine

```bash
# Launch the container (auto-detects GPU)
./run-container.sh

# You are now inside the container. Build the engine:
./dev-container/build-engine.sh
```

This takes ~20-40 minutes depending on your CPU (compiles 1047 targets).

### Step 3: Run O3DE

```bash
# Still inside the container, run the Project Manager:
./build/bin/debug/o3de

# Or run the Editor directly (requires a project):
./build/bin/debug/Editor
```

---

## Complete Workflow Example (NVIDIA)

```bash
# === ON YOUR HOST MACHINE ===

# 1. Navigate to dev-container
cd /path/to/o3de/dev-container

# 2. Build the Docker image (first time only)
docker compose --profile nvidia build

# 3. Launch the container
./run-container.sh

# === NOW INSIDE THE CONTAINER ===

# 4. Build the engine (first time only, ~30 min)
./dev-container/build-engine.sh

# 5. Run the Project Manager
./build/bin/debug/o3de

# 6. Exit when done
exit
```

---

## Complete Workflow Example (AMD)

```bash
# === ON YOUR HOST MACHINE ===

# 1. Navigate to dev-container
cd /path/to/o3de/dev-container

# 2. Build the Docker image (first time only)
docker compose --profile amd build

# 3. Launch the container
./run-container.sh

# === NOW INSIDE THE CONTAINER ===

# 4. Build the engine (first time only, ~30 min)
./dev-container/build-engine.sh

# 5. Run the Project Manager
./build/bin/debug/o3de

# 6. Exit when done
exit
```

---

## Troubleshooting

### "permission denied" when running docker commands
```bash
# Add yourself to docker group and re-login
sudo usermod -aG docker $USER
# Then log out and back in
```

### "NVIDIA driver not found" or GPU not detected in container
```bash
# Verify nvidia-container-toolkit is installed
nvidia-container-cli --version

# Verify your GPU is visible
nvidia-smi

# If nvidia-smi works on host but not in container, restart docker:
sudo systemctl restart docker
```

### "could not select device driver" error
```bash
# Install nvidia-container-toolkit
sudo apt-get install -y nvidia-container-toolkit
sudo systemctl restart docker
```

### Project Manager or Editor crashes immediately
```bash
# Make sure X11 forwarding is working
echo $DISPLAY  # Should show something like ":0" or ":1"

# Try running with explicit DISPLAY
DISPLAY=:0 ./build/bin/debug/o3de
```

### Force a specific GPU profile
```bash
# Override auto-detection
./run-container.sh --profile nvidia
./run-container.sh --profile amd
./run-container.sh --profile intel
```

---

## What This Container Provides

| Component | Version |
|-----------|---------|
| Base OS | Ubuntu 22.04 |
| C++ Compiler | Clang 14, GCC 13 |
| CMake | 3.28.3 |
| Build System | Ninja |
| Graphics | Vulkan, Mesa |

Your source code is mounted from the host at `/home/devuser/o3de`, so:
- Edits on your host are immediately visible in the container
- Build artifacts persist on your host filesystem
- You only need to rebuild the engine when source changes

---

## File Reference

| File | Purpose |
|------|---------|
| `Dockerfile.dev` | Container image definition |
| `docker-compose.yml` | GPU profiles (nvidia/amd/intel) |
| `run-container.sh` | Main entry point with auto-detection |
| `build-engine.sh` | Builds O3DE inside container |
| `entrypoint.sh` | Container startup script |

---

## GPU Support Matrix

| GPU Vendor | Tested | Host Requirements |
|------------|--------|-------------------|
| NVIDIA | Yes (RTX 4070) | `nvidia-driver-xxx`, `nvidia-container-toolkit` |
| AMD | Yes | AMDGPU kernel driver (usually built-in) |
| Intel | No | i915 kernel driver (usually built-in) |

---

## Session Notes

### 2025-05: Initial development
- Created initial container setup
- Achieved functional Linux build in container
- Achieved functional runtime on AMD GPU

### 2026-01: GPU-neutral implementation
- Implemented Docker Compose profiles for NVIDIA/AMD/Intel
- Added GPU auto-detection to `run-container.sh`
- Tested and confirmed working:
  - NVIDIA RTX 4070: GPU passthrough, engine build, Project Manager GUI
  - AMD: GPU passthrough, engine build, runtime (tested 2025-05)
