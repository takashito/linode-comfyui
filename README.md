# ComfyUI on Linode RTX 4000 ADA Instance

Docker based ComfyUI deployment with Linode RTX 4000 ADA Instance, HTTPS reverse proxy, and GPU monitoring.

## What is this project?

This project provides an simple automated deployment script for installing [ComfyUI](https://github.com/comfyanonymous/ComfyUI), a powerful and modular stable diffusion GUI.

script automatically install
- **ComfyUI** - Node-based interface for Stable Diffusion image generation
- **Caddy** - Automatic HTTPS reverse proxy with basic authentication
- **GPU Monitor** - Web-based nvtop interface for real-time GPU monitoring
- **ComfyUI Manager** - Pre-installed for easy custom node management

---

## Prerequisites

### 1. NVIDIA GPU and Driver

You must have an NVIDIA GPU with proper drivers installed:

```bash
# Check if NVIDIA driver is installed
nvidia-smi
```

If the command fails or shows no GPU, install the NVIDIA driver first:

**Ubuntu/Debian:**
```bash
# Check available drivers
ubuntu-drivers devices

# Install recommended driver
sudo ubuntu-drivers autoinstall

# OR install specific version
# sudo apt install nvidia-driver-535

# Reboot after installation
sudo reboot

# Verify installation
nvidia-smi
```

**Manual Installation:**
Visit [NVIDIA Driver Downloads](https://www.nvidia.com/Download/index.aspx) for your specific GPU model.


### 2. Recommended Cloud Instance

**Linode RTX4000 Ada x1 Medium**
- **GPU**: NVIDIA RTX 4000 Ada (20GB VRAM) x1
- **CPU**: 8 vCPUs
- **RAM**: 32GB
- **Disk**: 500TB
- **OS**: Ubuntu 22.04 or later

This instance provides good performance and cost balance for ComfyUI workflows. The 20GB VRAM can handle most Stable Diffusion models including latest model like Wan2.2 14B.

---

## Setup Process

### Step 1: Clone or Download the Project

```bash
# Clone to any directory you prefer
git clone https://github.com/takashito/linode-comfyui.git
cd linode-comfyui
```

Or download and extract the files to your preferred location.

### Step 2: Install Docker and NVIDIA Container Toolkit

Run the Docker setup script:

```bash
sudo bash setup-docker.sh
```

This script will:
- Install Docker and Docker Compose
- Install NVIDIA Container Toolkit
- Configure Docker to use NVIDIA runtime
- Restart Docker daemon

**Verify GPU access:**
```bash
docker run --rm --gpus all nvidia/cuda:11.8.0-base-ubuntu22.04 nvidia-smi
```

You should see your GPU information displayed.

### Step 3: Configure and Deploy ComfyUI

Run the ComfyUI setup script:

```bash
sudo bash setup-comfyui.sh
```

The script will interactively prompt you for:

1. **Domain(s)**: Your domain name(s) for HTTPS access
   - Example: `comfyui.example.com`
   - Multiple domains: `comfyui.example.com, alt.example.com`

2. **Username**: Basic auth username for web access
   - Example: `admin`

3. **Password**: Basic auth password (hidden input)
   - Choose a strong password

The script will then:
- Generate a secure password hash
- Update the Caddyfile configuration
- Create necessary directories
- Build Docker images (this may take 3-5 minutes)
- Start all services
- Configure systemd for auto-start

### Step 4: DNS Configuration

Before accessing your deployment, ensure your domain's DNS A record points to your server's IP address:

```
Type: A
Name: comfyui (or @ for root domain)
Value: YOUR_SERVER_IP
TTL: 3600
```

Wait for DNS propagation (usually 5-60 minutes).

### Accessing ComfyUI

Once setup is complete:

- **ComfyUI Interface**: `https://your-domain.com`
- **GPU Monitor**: `https://your-domain.com/monitor`

Enter the username and password you configured during setup.

### Directory Structure

```
.
├── README.md                    # This file
├── setup-docker.sh              # Docker & NVIDIA setup script
├── setup-comfyui.sh             # ComfyUI deployment script
├── docker-compose.yml           # Docker Compose configuration
├── Caddyfile                    # Caddy reverse proxy config (auto-generated)
├── Dockerfile.comfyui           # ComfyUI container definition
├── Dockerfile.gpu-monitor       # GPU monitor container definition
├── models/                      # Stable Diffusion models
│   ├── diffusion_models/        # Checkpoint files (.safetensors, .ckpt)
│   ├── vae/                     # VAE models
│   └── text_encoders/           # CLIP and text encoder models
├── input/                       # Input images
├── output/                      # Generated images
├── custom_nodes/                # ComfyUI custom nodes
└── user/                        # User configuration and workflows
```

---

## Managing the Deployment

### Service Control

```bash
# Check service status
sudo systemctl status comfyui-compose.service

# View logs
sudo journalctl -u comfyui-compose.service -f

# Restart services
sudo systemctl restart comfyui-compose.service

# Stop services
sudo systemctl stop comfyui-compose.service

# Start services
sudo systemctl start comfyui-compose.service
```

### Docker Commands

```bash
# View running containers
docker ps

# View logs
docker compose logs -f

# Restart specific service
docker restart comfyui
docker restart caddy
docker restart gpu-monitor

# Access ComfyUI container shell
docker exec -it comfyui bash

# Stop all services
docker compose down

# Start all services
docker compose up -d
```

### Installing Custom Nodes

**Method 1: Using ComfyUI Manager (Recommended)**

1. Access ComfyUI web interface
2. Click on "Manager" button
3. Browse and install custom nodes
4. Restart ComfyUI container: `docker restart comfyui`

**Method 2: Manual Installation**

```bash
# Access container
docker exec -it comfyui bash

# Navigate to custom nodes directory
cd /opt/ComfyUI/custom_nodes

# Clone the custom node repository
git clone https://github.com/author/custom-node-repo.git

# Exit container
exit

# Restart ComfyUI
docker restart comfyui
```

### Adding Models

Place your model files in the appropriate directories:

```bash
# Stable Diffusion checkpoints
./models/diffusion_models/

# VAE models
./models/vae/

# Text encoders (CLIP, etc.)
./models/text_encoders/
```

Models are automatically mounted and available in ComfyUI.

---

## Support and Resources

- [ComfyUI Documentation](https://github.com/comfyanonymous/ComfyUI)
- [ComfyUI Manager](https://github.com/ltdrdata/ComfyUI-Manager)
- [Caddy Documentation](https://caddyserver.com/docs/)
- [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html)

---

## License

This deployment configuration is provided as-is. ComfyUI and other components have their own licenses.
