#!/usr/bin/env bash
set -euo pipefail

# Bootstrap script for a Hermes Agent Azure VM (1GB RAM / 2 vCPU)
# Re-applies all optimizations from the vm-setup configs.
# Run as root or with sudo.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$SCRIPT_DIR/configs"
ZRAM_DIR="$SCRIPT_DIR/scripts/zram"

echo "=== Azure VM Low-RAM Bootstrap ==="

# ----- 1. ZRAM (custom service — systemd-zram-generator was unreliable) -----
echo "[1] Setting up ZRAM swap (512M, lzo-rle)..."
cp "$ZRAM_DIR/zram-swap-setup.sh" /usr/local/bin/zram-swap-setup.sh
cp "$ZRAM_DIR/zram-swap-teardown.sh" /usr/local/bin/zram-swap-teardown.sh
cp "$ZRAM_DIR/zram-swap.service" /etc/systemd/system/zram-swap.service
chmod +x /usr/local/bin/zram-swap-*.sh
systemctl daemon-reload
# Mask the generator so it doesn't fight our custom service
systemctl mask systemd-zram-setup@zram0.service 2>/dev/null || true
systemctl enable --now zram-swap.service
echo "  OK — 512M lzo-rle ZRAM swap active"

# ----- 2. Lower swappiness -----
echo "[2] Setting swappiness=10..."
cp "$CONFIG_DIR/99-swappiness.conf" /etc/sysctl.d/99-swappiness.conf
sysctl vm.swappiness=10
echo "  OK"

# ----- 3. vfs_cache_pressure (more dentry/inode cache) -----
echo "[3] Setting vfs_cache_pressure=50..."
cp "$CONFIG_DIR/50-vfs-cache-pressure.conf" /etc/sysctl.d/50-vfs-cache-pressure.conf
sysctl vm.vfs_cache_pressure=50
echo "  OK"

# ----- 4. Remove old swap file -----
echo "[4] Removing old disk swap file..."
swapoff /swapfile 2>/dev/null || true
sed -i '/swapfile/d' /etc/fstab 2>/dev/null || true
rm -f /swapfile
echo "  OK — 2GB reclaimed"

# ----- 5. Cap journald -----
echo "[5] Capping journald to 50MB..."
grep -q "^SystemMaxUse=50M" /etc/systemd/journald.conf 2>/dev/null || \
  cat "$CONFIG_DIR/journald-override.conf" >> /etc/systemd/journald.conf
systemctl restart systemd-journald
echo "  OK"

# ----- 6. Disable unnecessary services -----
echo "[6] Disabling ModemManager (mobile broadband — useless on Azure)..."
systemctl stop ModemManager.service 2>/dev/null || true
systemctl disable ModemManager.service 2>/dev/null || true

echo "[7] Disabling udisks2 (desktop disk management)..."
systemctl stop udisks2.service 2>/dev/null || true
systemctl disable udisks2.service 2>/dev/null || true

echo "[8] Disabling fwupd (firmware updater — useless on Azure VM)..."
systemctl stop fwupd.service 2>/dev/null || true
systemctl disable fwupd.service 2>/dev/null || true

echo "[9] Disabling multipathd (SAN multipath — not needed)..."
systemctl stop multipathd.service 2>/dev/null || true
systemctl disable multipathd.service 2>/dev/null || true
echo "  OK"

# ----- 7. Remove snapd (no snaps installed) -----
echo "[10] Removing snapd (zero snaps used)..."
systemctl stop snapd.service snapd.socket 2>/dev/null || true
apt-get purge -y snapd
echo "  OK"

# ----- 8. Disable packagekitd -----
echo "[11] Masking packagekitd (18MB background daemon)..."
systemctl stop packagekit.service 2>/dev/null || true
systemctl mask packagekit.service --now 2>/dev/null || true
echo "  OK"

# ----- 9. Install earlyoom -----
echo "[12] Installing earlyoom (OOM safety net)..."
apt-get install -y earlyoom
cp "$CONFIG_DIR/earlyoom" /etc/default/earlyoom
systemctl restart earlyoom
echo "  OK — prefer node, avoid hermes/python/sshd/systemd"

# ----- 10. Keep ctrld -----
echo "Keeping ctrld DNS proxy (as configured by user)"
echo "  Config: $CONFIG_DIR/ctrld.toml"

echo ""
echo "=== Bootstrap complete ==="
echo "Reboot to verify all services come up cleanly."
echo "After reboot, Hermes gateway will auto-start (linger enabled)."
