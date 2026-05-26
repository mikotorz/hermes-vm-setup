#!/bin/bash
set -e

# Make sure the zram module is loaded with a device
if [ ! -b /dev/zram0 ]; then
    modprobe zram num_devices=1
fi

# Skip if already configured (disksize already written)
if [ -f /sys/block/zram0/disksize ] && [ "$(cat /sys/block/zram0/disksize 2>/dev/null)" != "0" ]; then
    exit 0
fi

# Configure ZRAM
echo lzo-rle > /sys/block/zram0/comp_algorithm
echo 256M > /sys/block/zram0/disksize
mkswap /dev/zram0
swapon -p 100 /dev/zram0
