#!/usr/bin/env bash
set -euo pipefail

# Bootstrap script for a Hermes Agent Azure VM (1GB RAM / 2 vCPU)
# Re-applies all optimizations from the vm-setup configs.
# Run as root or with sudo.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$SCRIPT_DIR/configs"

echo "=== Azure VM Low-RAM Bootstrap ==="

# ----- 1. ZRAM (compressed in-memory swap) -----
echo "[1/8] Installing systemd-zram-generator..."
apt-get install -y systemd-zram-generator
cp "$CONFIG_DIR/zram-generator.conf" /etc/systemd/zram-generator.conf
echo "  OK — ZRAM will activate on next boot"

# ----- 2. Lower swappiness -----
echo "[2/8] Setting swappiness=10..."
cp "$CONFIG_DIR/99-swappiness.conf" /etc/sysctl.d/99-swappiness.conf
sysctl vm.swappiness=10
echo "  OK"

# ----- 3. Remove old swap file -----
echo "[3/8] Removing old disk swap file..."
swapoff /swapfile 2>/dev/null || true
sed -i '/swapfile/d' /etc/fstab 2>/dev/null || true
rm -f /swapfile
echo "  OK — 2GB reclaimed"

# ----- 4. Cap journald -----
echo "[4/8] Capping journald to 50MB..."
grep -q "^SystemMaxUse=50M" /etc/systemd/journald.conf 2>/dev/null || \
  cat "$CONFIG_DIR/journald-override.conf" >> /etc/systemd/journald.conf
systemctl restart systemd-journald
echo "  OK"

# ----- 5. Disable unnecessary services -----
echo "[5/8] Disabling ModemManager (mobile broadband — useless on Azure)..."
systemctl stop ModemManager.service 2>/dev/null || true
systemctl disable ModemManager.service 2>/dev/null || true

echo "[6/8] Disabling udisks2 (desktop disk management)..."
systemctl stop udisks2.service 2>/dev/null || true
systemctl disable udisks2.service 2>/dev/null || true

echo "[7/8] Disabling multipathd (SAN multipath — not needed)..."
systemctl stop multipathd.service 2>/dev/null || true
systemctl disable multipathd.service 2>/dev/null || true

echo "  OK"

# ----- 6. Remove snapd (no snaps installed) -----
echo "[8/8] Removing snapd (zero snaps used)..."
systemctl stop snapd.service snapd.socket 2>/dev/null || true
apt-get purge -y snapd
echo "  OK"

# ----- 7. Disable packagekitd -----
echo "[9/8] Masking packagekitd (18MB background daemon)..."
systemctl stop packagekit.service 2>/dev/null || true
systemctl mask packagekit.service --now 2>/dev/null || true
echo "  OK"

# ----- 8. Install earlyoom -----
echo "[10/8] Installing earlyoom (OOM safety net)..."
apt-get install -y earlyoom
systemctl enable --now earlyoom
echo "  OK"

# ----- 9. Keep ctrld -----
echo "Keeping ctrld DNS proxy (as configured by user)"
echo "  Config: $CONFIG_DIR/ctrld.toml"

echo ""
echo "=== Bootstrap complete ==="
echo "Reboot to activate ZRAM swap and pick up all changes."
echo "After reboot, Hermes gateway will auto-start (linger enabled)."