#!/usr/bin/env bash

set -e  # Exit on error

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== ComfyUI Configuration ==="
echo ""

# Prompt for domain(s)
read -p "Enter your domain(s) (space or comma-separated, e.g., 'comfyui.example.com' or 'comfyui.example.com, www.example.com'): " DOMAINS_INPUT
if [ -z "$DOMAINS_INPUT" ]; then
    echo "Error: Domain is required"
    exit 1
fi

# Clean up domain input (replace commas with spaces, remove extra spaces)
DOMAINS=$(echo "$DOMAINS_INPUT" | sed 's/,/ /g' | tr -s ' ')

echo ""
echo "Configuring for domain(s): $DOMAINS"
echo ""

# Prompt for basic auth credentials
read -p "Enter basic auth username: " AUTH_USER
if [ -z "$AUTH_USER" ]; then
    echo "Error: Username is required"
    exit 1
fi

read -sp "Enter basic auth password: " AUTH_PASS
echo ""
if [ -z "$AUTH_PASS" ]; then
    echo "Error: Password is required"
    exit 1
fi

echo ""
echo "Generating password hash..."

# Install apache2-utils if not already installed (needed for htpasswd)
if ! command -v htpasswd &> /dev/null; then
    echo "Installing apache2-utils for password hashing..."
    apt-get update
    apt-get install -y apache2-utils
fi

# Generate bcrypt hash for the password (Caddy uses bcrypt with cost 14)
AUTH_HASH=$(htpasswd -nbB "$AUTH_USER" "$AUTH_PASS" | cut -d: -f2)

# Update Caddyfile
echo "Updating Caddyfile..."
CADDYFILE_PATH="$SCRIPT_DIR/Caddyfile"

cat > "$CADDYFILE_PATH" <<EOF
$DOMAINS {
  encode zstd gzip

  basicauth {
    $AUTH_USER $AUTH_HASH
  }

  # GPU monitor path - must come before the catch-all
  handle_path /monitor* {
    reverse_proxy gpu-monitor:8082
  }

  # ComfyUI main application - catch-all for everything else
  handle {
    reverse_proxy comfyui:8188 {
      transport http {
         read_timeout 600s
         write_timeout 600s
         dial_timeout 10s
      }
    }
  }
}
EOF

echo "Caddyfile updated successfully!"
echo ""

# Create directory structure in the project directory
echo "Creating directory structure..."
cd "$SCRIPT_DIR"
mkdir -p models/{diffusion_models,vae,text_encoders}
mkdir -p input output custom_nodes user

# build docker files & start compose
echo "Building and starting services..."
docker compose build --no-cache
docker compose up -d

echo ""
echo "Setting up systemd service..."
# Update the systemd service file to use the current directory
SYSTEMD_SERVICE_PATH="/etc/systemd/system/comfyui-compose.service"

cat > "$SYSTEMD_SERVICE_PATH" <<EOF
[Unit]
Description=ComfyUI
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
WorkingDirectory=$SCRIPT_DIR
Environment=COMPOSE_PROJECT_NAME=comfyui
ExecStart=/usr/bin/docker compose up -d
ExecStop=/usr/bin/docker compose stop
RemainAfterExit=yes
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now comfyui-compose.service

echo ""
echo "Setup complete!"
echo "Project directory: $SCRIPT_DIR"
echo "Your ComfyUI is now accessible at: https://$DOMAINS"
echo "Username: $AUTH_USER"
echo "GPU Monitor: https://$DOMAINS/monitor"
echo ""
