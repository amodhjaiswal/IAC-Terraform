#!/bin/bash
# ============================================================
# EC2 User Data Script
# Installs AWS CLI v2, kubectl, and eksctl on Ubuntu
# Logs output to /var/log/user-data.log
# ============================================================

# Log all output to console and file
exec > >(tee /var/log/user-data.log | logger -t user-data -s 2>/dev/console) 2>&1
set -e

echo "=== Starting system update ==="
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get upgrade -y

echo "=== Installing core dependencies ==="
apt-get install -y \
    unzip \
    curl \
    tar \
    wget \
    gnupg \
    lsb-release \
    ca-certificates \
    software-properties-common \
    apt-transport-https \
    git \
    vim \
    jq \
    python3 \
    python3-pip

# Wait for dpkg lock to be released
while fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; do
    echo "Waiting for dpkg lock..."
    sleep 5
done

# ------------------------------------------------------------
# Install AWS CLI v2
# ------------------------------------------------------------
echo "=== Installing AWS CLI v2 ==="
cd /tmp
curl -f "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
if [ ! -f "awscliv2.zip" ]; then
    echo "ERROR: Failed to download AWS CLI"
    exit 1
fi

unzip -o awscliv2.zip
sudo ./aws/install --update
rm -rf awscliv2.zip aws

# Verify AWS CLI installation
if ! aws --version; then
    echo "ERROR: AWS CLI installation failed"
    exit 1
fi
echo "AWS CLI installed successfully"

# ------------------------------------------------------------
# Install kubectl (latest stable version)
# ------------------------------------------------------------
echo "=== Installing kubectl ==="
cd /tmp
KUBECTL_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt)
curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
if [ ! -f "kubectl" ]; then
    echo "ERROR: Failed to download kubectl"
    exit 1
fi

sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm -f kubectl

# Verify kubectl installation
if ! kubectl version --client; then
    echo "ERROR: kubectl installation failed"
    exit 1
fi
echo "kubectl installed successfully"

# ------------------------------------------------------------
# Install eksctl
# ------------------------------------------------------------
echo "=== Installing eksctl ==="
cd /tmp
curl --silent --location "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" \
  | tar xz -C /tmp
if [ ! -f "eksctl" ]; then
    echo "ERROR: Failed to download eksctl"
    exit 1
fi

sudo mv eksctl /usr/local/bin/
sudo chmod +x /usr/local/bin/eksctl

# Verify eksctl installation
if ! eksctl version; then
    echo "ERROR: eksctl installation failed"
    exit 1
fi
echo "eksctl installed successfully"

# ------------------------------------------------------------
# Install Helm (optional but useful for EKS)
# ------------------------------------------------------------
echo "=== Installing Helm ==="
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
if ! helm version; then
    echo "WARNING: Helm installation failed, continuing..."
fi

# ------------------------------------------------------------
# Save tool versions and create completion marker
# ------------------------------------------------------------
echo "=== Saving tool versions to /root/tool_versions.txt ==="
{
  echo "=== Tool Installation Summary ==="
  echo "Installation Date: $(date)"
  echo "Instance ID: $(curl -s http://169.254.169.254/latest/meta-data/instance-id)"
  echo
  echo "AWS CLI Version:"
  aws --version
  echo
  echo "kubectl Version:"
  kubectl version --client
  echo
  echo "eksctl Version:"
  eksctl version
  echo
  echo "Helm Version:"
  helm version --short 2>/dev/null || echo "Helm not installed"
  echo
  echo "Python3 Version:"
  python3 --version
  echo
  echo "Git Version:"
  git --version
} > /root/tool_versions.txt

# Create completion marker
touch /var/log/user-data-complete
echo "=== Installation completed successfully at $(date) ==="
echo "=== All dependencies installed and verified ==="
