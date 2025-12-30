# NixOS Tor Middle Relay on Hetzner Cloud

This is a ready-to-use NixOS configuration to set up a **Tor Middle Relay** on a Hetzner Cloud VPS. It is optimized for a 15TB traffic limit and 100Mbit bandwidth.

## Features
* **Tor Middle Node:** Pre-configured on Port 443 (IPv4/IPv6).
* **Limits:** 15TB/Month traffic limit (hibernates afterwards) & 12.5MB/s speed limit.
* **Security:** Fail2Ban enabled, SSH Root login disabled.
* **Maintenance:** Auto-updates and auto-reboot enabled (Daily 04:00).

## Installation Guide

### 1. Partitioning (Crucial!)
Since Hetzner VPS often boot in legacy BIOS mode, this config uses GRUB. You need a specific partition layout (GPT with a BIOS Boot Partition).

Boot the server into the NixOS ISO (Rescue System), become root (`sudo -i`) and run:

```bash
# Create Partition Table
parted /dev/sda -- mklabel gpt

# 1. BIOS Boot Partition (Required for GRUB!)
parted /dev/sda -- mkpart primary 1MB 2MB
parted /dev/sda -- set 1 bios_grub on

# 2. Boot Partition
parted /dev/sda -- mkpart primary 2MB 514MB

# 3. Root Partition
parted /dev/sda -- mkpart primary 514MB 100%

# Format
mkfs.ext4 -L boot /dev/sda2
mkfs.ext4 -L nixos /dev/sda3

# Mount
mount /dev/disk/by-label/nixos /mnt
mkdir -p /mnt/boot
mount /dev/disk/by-label/boot /mnt/boot
```

### 2. Generate Config
```bash
nixos-generate-config --root /mnt
```

### 3. Download & Edit Config
Copy the content of `configuration.nix` from this repository to `/mnt/etc/nixos/configuration.nix`.

**Make sure to edit the `TODO` placeholders:**
* `YOUR_HOSTNAME`
* `YOUR_USERNAME`
* `YOUR_RELAY_NICKNAME` (Max 19 chars!)

### 4. Install
```bash
nixos-install
```

### 5. Set Password
Before rebooting, set a password for your user:
```bash
nixos-enter
passwd YOUR_USERNAME
exit
```

### 6. Reboot
```bash
reboot
```
