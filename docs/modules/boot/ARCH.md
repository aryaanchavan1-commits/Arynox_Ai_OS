# Boot System Architecture

## Overview

The Arynox boot system is built on systemd-boot (for UEFI systems) with fallback to GRUB for legacy BIOS and ARM devices. It provides:

- Fast boot (target: <10s to desktop)
- Secure Boot with custom keys
- TPM-based measured boot and disk decryption
- BTRFS snapshot support in boot menu
- Recovery partition boot
- Factory reset option
- Custom Plymouth splash theme

## Boot Flow

```
Power On
    │
    ▼
UEFI Firmware → Secure Boot verification
    │
    ▼
systemd-boot menu (with Arynox theme)
    │
    ├── Arynox OS (default)
    ├── Arynox OS (Recovery)
    ├── Arynox OS (Previous Snapshot)
    └── Firmware Setup
    │
    ▼
Linux Kernel (signed, measured by TPM)
    │
    ▼
Initramfs → decrypt LUKS (TPM or passphrase)
    │
    ▼
Switch root → systemd
    │
    ▼
systemd-boot-checkboot-finished → boot-complete.target
    │
    ▼
Arynox Session Manager starts
    │
    ▼
Desktop ready
```

## Partition Layout

| Partition | Size | FS | Mount | Purpose |
|-----------|------|----|-------|---------|
| ESP | 512MB | FAT32 | /efi | EFI System Partition with bootloaders |
| Boot | 1GB | ext4 | /boot | Kernel images, initramfs |
| Root | rest | BTRFS | / | Main system with subvolumes |
| Recovery | 8GB | BTRFS | /recovery | Recovery environment |
| Swap | RAM × 1 | swap | | Swap (optional, zram fallback) |

## BTRFS Subvolumes

```
@           → /
@home       → /home
@snapshots  → /.snapshots
@var        → /var
@tmp        → /tmp
@cache      → /var/cache
@recovery   → /recovery
```

## systemd Units

- `arynox-boot-complete.service` — Signals boot completion
- `arynox-session.service` — Starts the desktop session
- `arynox-tpm-unlock.service` — TPM-based LUKS unlock
- `arynox-boot-splash.service` — Plymouth splash management
- `arynox-check-boot.service` — Boot health check

## Bootloader Config

systemd-boot with custom Arynox entries for:
- Normal boot
- Recovery mode
- Last known good snapshot
- Memtest86
- Firmware setup
