#!/bin/bash
set -euo pipefail

echo "======================================"
echo " Docker & Docker Compose Setup"
echo "      RHEL 9.6 (Pinned Version)"
echo "======================================"

# 1. Root check
if [[ "$EUID" -ne 0 ]]; then
  echo "❌ Run this script as root or with sudo"
  exit 1
fi

PKG_MGR=dnf

# 2. Remove old Docker versions
echo "🧹 Removing old Docker versions (if any)"
$PKG_MGR remove -y \
  docker \
  docker-client \
  docker-client-latest \
  docker-common \
  docker-latest \
  docker-latest-logrotate \
  docker-logrotate \
  docker-engine || true

# 3. Install prerequisites
echo "📦 Installing prerequisites"
$PKG_MGR install -y \
  dnf-plugins-core \
  dnf-plugin-versionlock \
  curl

# 4. Add Docker official repo (CentOS repo is CORRECT for RHEL 9)
echo "📚 Adding Docker repository"
$PKG_MGR config-manager --add-repo \
  https://download.docker.com/linux/centos/docker-ce.repo

# 5. Refresh metadata
$PKG_MGR makecache

# 6. Define Docker version (NO EPOCH HERE — THIS IS CRITICAL)
DOCKER_VERSION="26.1.4-1.el9"

# 7. Install Docker (pinned version)
echo "🐳 Installing Docker Engine version ${DOCKER_VERSION}"
$PKG_MGR install -y \
  docker-ce-${DOCKER_VERSION} \
  docker-ce-cli-${DOCKER_VERSION} \
  containerd.io \
  docker-buildx-plugin \
  docker-compose-plugin

# 8. Enable & start Docker
echo "🚀 Enabling Docker service"
systemctl enable --now docker

# 9. Add docker group + user
getent group docker >/dev/null || groupadd docker

if [[ -n "${SUDO_USER:-}" ]]; then
  usermod -aG docker "$SUDO_USER"
  echo "👤 Added $SUDO_USER to docker group"
fi

# 10. Lock versions (epoch handled automatically)
echo "🔒 Locking Docker versions"
$PKG_MGR versionlock add \
  docker-ce \
  docker-ce-cli \
  containerd.io

# 11. Verification
echo "======================================"
echo " 🔍 Verification"
echo "======================================"

docker --version
docker compose version
docker run --rm hello-world

echo "======================================"
echo "✅ Docker installation SUCCESS"
echo "👉 Logout/login required for non-root"
echo "======================================"
