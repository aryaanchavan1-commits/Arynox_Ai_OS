#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# Arynox OS Build Script — generates a bootable ISO
# Run inside Ubuntu 24.04+ (WSL2, native, or Docker)
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_DIR/build"
ISO_DIR="$BUILD_DIR/iso"
ROOTFS_DIR="$BUILD_DIR/rootfs"
INITRAMFS_DIR="$BUILD_DIR/initramfs"
CACHE_DIR="$BUILD_DIR/cache"
RELEASE_DIR="$PROJECT_DIR/release"

ARCH="${ARCH:-amd64}"
VERSION="${VERSION:-0.1.0}"
KERNEL_VERSION="${KERNEL_VERSION:-6.6.30}"
CORES=$(nproc 2>/dev/null || echo 4)

mkdir -p "$BUILD_DIR" "$ISO_DIR" "$ROOTFS_DIR" "$INITRAMFS_DIR" "$CACHE_DIR" "$RELEASE_DIR"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
log()  { echo -e "${GREEN}[ARYNOX]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
err()  { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# ============================================================================
# Phase 1: Install build dependencies
# ============================================================================
phase_install_deps() {
    log "Phase 1: Installing build dependencies..."

    apt-get update -qq
    apt-get install -y -qq \
        build-essential curl git pkg-config \
        libwayland-dev libxkbcommon-dev libegl1-mesa-dev libgles2-mesa-dev \
        libdbus-1-dev libsystemd-dev libudev-dev libinput-dev \
        libdrm-dev libgbm-dev libseat-dev \
        libssl-dev libsqlite3-dev libpam-dev \
        squashfs-tools xorriso grub-pc-bin grub-efi-amd64-bin \
        dosfstools mtools btrfs-progs \
        python3 python3-pip python3-venv \
        cmake ninja-build \
        debootstrap \
        wget cpio \
        libtss2-dev \
        libasound2-dev libpulse-dev \
        fd-find ripgrep \
        --no-install-recommends

    # Install Rust
    if ! command -v rustc &>/dev/null; then
        log "Installing Rust..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        source "$HOME/.cargo/env"
    fi
    rustup default stable
    rustup component add clippy rustfmt

    # Install Flutter
    if ! command -v flutter &>/dev/null; then
        log "Installing Flutter..."
        git clone --depth=1 -b stable https://github.com/flutter/flutter.git "$CACHE_DIR/flutter" 2>/dev/null || true
        export PATH="$CACHE_DIR/flutter/bin:$PATH"
        flutter config --enable-linux-desktop 2>/dev/null || true
        flutter precache --linux 2>/dev/null || true
    fi
    export PATH="$CACHE_DIR/flutter/bin:$PATH"

    # Python dependencies
    pip3 install --quiet poetry pydantic httpx aiohttp dbus-next

    log "Phase 1 complete"
}

# ============================================================================
# Phase 2: Build all Rust crates
# ============================================================================
phase_build_rust() {
    log "Phase 2: Building Rust crates..."

    source "$HOME/.cargo/env" 2>/dev/null || true

    cd "$PROJECT_DIR"

    # Build core daemons
    for crate in core/arynox-tpm core/arynox-boot-check core/arynox-session; do
        log "  Building $crate..."
        cargo build --release --manifest-path "$crate/Cargo.toml" 2>&1 | tail -5
    done

    # Build module daemons
    for crate in src/wm src/files src/devices src/packages src/security src/cloud src/devtools src/updates src/installer src/recovery src/network; do
        log "  Building $crate..."
        cargo build --release --manifest-path "$crate/Cargo.toml" 2>&1 | tail -5
    done

    log "Phase 2 complete"
}

# ============================================================================
# Phase 3: Build Flutter apps
# ============================================================================
phase_build_flutter() {
    log "Phase 3: Building Flutter apps..."

    export PATH="$CACHE_DIR/flutter/bin:$PATH"
    export PATH="$HOME/.pub-cache/bin:$PATH"

    FLUTTER_APPS="desktop settings hub assistant copilot files devices software network devtools installer"

    for app in $FLUTTER_APPS; do
        local app_dir="$PROJECT_DIR/src/$app"
        if [ -f "$app_dir/pubspec.yaml" ]; then
            log "  Building $app..."
            cd "$app_dir"
            flutter pub get 2>&1 | tail -3
            flutter build linux --release 2>&1 | tail -5
        else
            warn "  Skipping $app (no pubspec.yaml)"
        fi
    done

    log "Phase 3 complete"
}

# ============================================================================
# Phase 4: Build Python AI runtime package
# ============================================================================
phase_build_python() {
    log "Phase 4: Building Python AI runtime..."

    cd "$PROJECT_DIR/ai-python"
    poetry build 2>&1 | tail -3

    log "Phase 4 complete"
}

# ============================================================================
# Phase 5: Create initramfs
# ============================================================================
phase_initramfs() {
    log "Phase 5: Creating initramfs..."

    local initramfs_dir="$INITRAMFS_DIR"
    rm -rf "$initramfs_dir"
    mkdir -p "$initramfs_dir"/{bin,dev,etc,lib,lib64,mnt,proc,root,run,sbin,sys,tmp,usr/lib,usr/share}

    # Copy busybox for essential tools
    if ! command -v busybox &>/dev/null; then
        apt-get install -y -qq busybox-static 2>/dev/null || true
    fi
    if [ -f /bin/busybox ]; then
        cp /bin/busybox "$initramfs_dir/bin/"
        # Create symlinks for essential commands
        for cmd in sh mount umount insmod modprobe ls cat echo grep dmesg mkdir rm mv cp chroot; do
            ln -sf /bin/busybox "$initramfs_dir/bin/$cmd"
        done
    fi

    # Copy Arynox boot utilities
    mkdir -p "$initramfs_dir/usr/lib/arynox"
    for bin in arynox-tpm arynox-boot-check; do
        local src="$PROJECT_DIR/target/release/$bin"
        [ -f "$src" ] && cp "$src" "$initramfs_dir/usr/lib/arynox/"
    done

    # Copy init script
    cp "$PROJECT_DIR/src/boot/initramfs/scripts/arynox-boot" "$initramfs_dir/init" 2>/dev/null || true
    chmod +x "$initramfs_dir/init" 2>/dev/null || true

    # Create initramfs cpio archive
    cd "$initramfs_dir"
    find . | cpio -H newc -o | gzip -9 > "$BUILD_DIR/initramfs.img"
    log "Initramfs created: $BUILD_DIR/initramfs.img (size: $(du -h "$BUILD_DIR/initramfs.img" | cut -f1))"
}

# ============================================================================
# Phase 6: Build kernel
# ============================================================================
phase_kernel() {
    log "Phase 6: Building Linux kernel..."

    local kernel_dir="$CACHE_DIR/linux-$KERNEL_VERSION"
    local kernel_config="$PROJECT_DIR/src/boot/kernel-config-6.6"

    if [ ! -d "$kernel_dir" ]; then
        log "  Downloading kernel $KERNEL_VERSION..."
        wget -q "https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-$KERNEL_VERSION.tar.xz" -O "$CACHE_DIR/linux.tar.xz"
        tar xf "$CACHE_DIR/linux.tar.xz" -C "$CACHE_DIR"
    fi

    cd "$kernel_dir"
    if [ -f "$kernel_config" ]; then
        cp "$kernel_config" .config
    else
        make defconfig
    fi

    # Apply Arynox patches if any
    if [ -d "$PROJECT_DIR/src/kernel/patches" ]; then
        for patch in "$PROJECT_DIR"/src/kernel/patches/*.patch; do
            [ -f "$patch" ] && patch -p1 < "$patch"
        done
    fi

    log "  Compiling kernel (this may take a while)..."
    make -j"$CORES" bzImage 2>&1 | tail -5

    cp arch/x86/boot/bzImage "$BUILD_DIR/vmlinuz-arynox"
    log "Kernel built: $BUILD_DIR/vmlinuz-arynox"
}

# ============================================================================
# Phase 7: Create squashfs root filesystem
# ============================================================================
phase_squashfs() {
    log "Phase 7: Creating squashfs root filesystem..."

    local rootfs="$ROOTFS_DIR"
    rm -rf "$rootfs"
    mkdir -p "$rootfs"/{bin,boot,dev,etc,home,lib,media,mnt,opt,proc,root,run,sbin,srv,sys,tmp,usr,var}
    mkdir -p "$rootfs/usr/{bin,lib,share,libexec}"
    mkdir -p "$rootfs/usr/lib/arynox"
    mkdir -p "$rootfs/var/lib/arynox"
    mkdir -p "$rootfs/etc/arynox"
    mkdir -p "$rootfs/etc/systemd/system"
    mkdir -p "$rootfs/usr/share/arynox"

    # Copy systemd units
    cp "$PROJECT_DIR/src/boot/systemd/"*.service "$rootfs/usr/lib/systemd/system/" 2>/dev/null || true

    # Copy compiled Rust binaries
    for bin in arynox-tpm arynox-boot-check arynox-session arynox-compositor; do
        local src="$PROJECT_DIR/target/release/$bin"
        [ -f "$src" ] && cp "$src" "$rootfs/usr/lib/arynox/"
    done

    # Copy module daemons
    for daemon in arynox-device-manager arynox-package-manager arynox-security arynox-cloud arynox-devtools arynox-updates arynox-installer arynox-recovery arynox-network; do
        local src="$PROJECT_DIR/target/release/$daemon"
        [ -f "$src" ] && cp "$src" "$rootfs/usr/lib/arynox/"
    done

    # Copy Flutter apps
    local flutter_out="$PROJECT_DIR/src"
    for app in desktop settings hub assistant copilot files devices software network devtools installer; do
        local app_dir="$flutter_out/$app/build/linux/x64/release/bundle"
        if [ -d "$app_dir" ]; then
            mkdir -p "$rootfs/usr/lib/arynox/apps/$app"
            cp -r "$app_dir"/* "$rootfs/usr/lib/arynox/apps/$app/"
            log "  Copied Flutter app: $app"
        fi
    done

    # Install Python AI runtime
    local whl=$(ls "$PROJECT_DIR/ai-python/dist/"*.whl 2>/dev/null | head -1)
    if [ -f "$whl" ]; then
        cp "$whl" "$rootfs/tmp/"
    fi

    # Create /etc/arynox configuration files
    cat > "$rootfs/etc/arynox/ai-runtime.yaml" << 'EOCONFIG'
providers:
  groq:
    api_key: ""
    base_url: "https://api.groq.com/openai/v1"
    default_model: "llama3-70b-8192"
    temperature: 0.7
    max_tokens: 4096
  openai:
    api_key: ""
    base_url: "https://api.openai.com/v1"
    default_model: "gpt-4o"
    temperature: 0.7
    max_tokens: 4096
  anthropic:
    api_key: ""
    base_url: "https://api.anthropic.com/v1"
    default_model: "claude-3-5-sonnet-20241022"
    temperature: 0.7
    max_tokens: 4096
  gemini:
    api_key: ""
    base_url: "https://generativelanguage.googleapis.com/v1beta"
    default_model: "gemini-1.5-pro"
    temperature: 0.7
    max_tokens: 4096
  ollama:
    api_key: ""
    base_url: "http://127.0.0.1:11434"
    default_model: "qwen2.5"
    temperature: 0.7
    max_tokens: 4096
  lmstudio:
    api_key: ""
    base_url: "http://127.0.0.1:1234/v1"
    default_model: "local-model"
    temperature: 0.7
    max_tokens: 4096
EOCONFIG

    cat > "$rootfs/etc/arynox/version" << 'EOVERSION'
ARYNOX_OS_VERSION="0.1.0"
ARYNOX_OS_CODENAME="Alpha"
KERNEL_VERSION="6.6.30"
BUILD_DATE="2026-07-15"
EOVERSION

    # Create essential device nodes
    mknod -m 666 "$rootfs/dev/null" c 1 3 2>/dev/null || true
    mknod -m 666 "$rootfs/dev/zero" c 1 5 2>/dev/null || true
    mknod -m 644 "$rootfs/dev/random" c 1 8 2>/dev/null || true
    mknod -m 644 "$rootfs/dev/urandom" c 1 9 2>/dev/null || true
    mknod -m 666 "$rootfs/dev/tty" c 5 0 2>/dev/null || true
    mknod -m 666 "$rootfs/dev/console" c 5 1 2>/dev/null || true

    # Create fstab
    cat > "$rootfs/etc/fstab" << 'EOFSTAB'
# Arynox OS filesystem table
/dev/root / btrfs subvol=@,compress=zstd,noatime 0 1
UUID=ARYNOX_HOME /home btrfs subvol=@home,compress=zstd,noatime 0 2
tmpfs /tmp tmpfs defaults,noatime,mode=1777 0 0
EOFSTAB

    # Create os-release
    cat > "$rootfs/usr/lib/os-release" << 'EORELEASE'
NAME="Arynox OS"
ID=arynox
PRETTY_NAME="Arynox OS 0.1.0 Alpha"
VERSION_ID="0.1.0"
VERSION_CODENAME="Alpha"
HOME_URL="https://arynox.com"
SUPPORT_URL="https://docs.arynox.com"
BUG_REPORT_URL="https://github.com/arynox/os/issues"
LOGO="arynox-logo"
EORELEASE

    # Create the squashfs
    log "  Creating squashfs..."
    mksquashfs "$rootfs" "$BUILD_DIR/filesystem.squashfs" \
        -comp zstd \
        -b 1M \
        -noappend \
        -always-use-fragments \
        -quiet

    local sq_size=$(du -h "$BUILD_DIR/filesystem.squashfs" | cut -f1)
    log "Squashfs created: $BUILD_DIR/filesystem.squashfs (size: $sq_size)"
}

# ============================================================================
# Phase 8: Generate bootable ISO
# ============================================================================
phase_iso() {
    log "Phase 8: Generating bootable ISO..."

    local iso="$ISO_DIR"
    rm -rf "$iso"
    mkdir -p "$iso"/{boot/grub,live,EFI/BOOT}

    # Copy kernel and initramfs
    cp "$BUILD_DIR/vmlinuz-arynox" "$iso/boot/"
    cp "$BUILD_DIR/initramfs.img" "$iso/boot/"

    # Copy squashfs
    cp "$BUILD_DIR/filesystem.squashfs" "$iso/live/"

    # Create GRUB configuration
    cat > "$iso/boot/grub/grub.cfg" << 'EOGRUB'
set default=0
set timeout=5

insmod all_video
insmod gfxterm
insmod gfxmenu
insmod btrfs
insmod ext2
insmod part_gpt

loadfont unicode

set gfxmode=auto
set gfxpayload=keep
terminal_output gfxterm

menuentry "Arynox OS" --class arynox --class os {
    set gfxpayload=keep
    echo "Loading Arynox OS kernel..."
    linux /boot/vmlinuz-arynox root=/dev/sda2 rootflags=subvol=@ rw quiet splash loglevel=3
    echo "Loading initramfs..."
    initrd /boot/initramfs.img
}

menuentry "Arynox OS (Recovery Mode)" --class arynox --class os {
    linux /boot/vmlinuz-arynox root=/dev/sda2 rootflags=subvol=@ rw quiet systemd.unit=recovery.target
    initrd /boot/initramfs.img
}

menuentry "Arynox OS (Safe Graphics)" --class arynox --class os {
    linux /boot/vmlinuz-arynox root=/dev/sda2 rootflags=subvol=@ rw quiet nomodeset
    initrd /boot/initramfs.img
}

menuentry "Memory Test (memtest86+)" --class memtest {
    linux16 /boot/memtest86+.bin
}

menuentry "Firmware Setup" --class firmware {
    fwsetup
}

if [ ${grub_platform} == "efi" ]; then
    menuentry "UEFI Firmware Settings" --class firmware {
        fwsetup
    }
fi

# Theme support
if [ -f /boot/grub/themes/arynox/theme.txt ]; then
    set theme=/boot/grub/themes/arynox/theme.txt
fi
EOGRUB

    # Create GRUB theme directory
    mkdir -p "$iso/boot/grub/themes/arynox"
    cat > "$iso/boot/grub/themes/arynox/theme.txt" << 'EOTHEME'
# Arynox OS GRUB Theme
title-text: "Arynox OS"
title-font: "DejaVu Sans Bold 16"
title-color: "#FFFFFF"
desktop-image: "background.png"
desktop-color: "#0F1023"
terminal-font: "DejaVu Sans Mono 12"

+ boot_menu {
    left = 25%
    top = 25%
    width = 50%
    height = 50%
    item_color = "#9CA3AF"
    selected_item_color = "#A29BFE"
    item_height = 32
    item_spacing = 8
    item_padding = 8
    item_font = "DejaVu Sans 14"
    selected_item_font = "DejaVu Sans Bold 14"
    selected_item_pixmap_style = "select_*.png"
}
EOTHEME

    # Create EFI boot (for UEFI systems)
    local efi_dir="$iso/EFI/BOOT"
    if [ -f /usr/lib/grub/x86_64-efi/grub.efi ]; then
        cp /usr/lib/grub/x86_64-efi/grub.efi "$efi_dir/bootx64.efi"
    fi

    # Build ISO with xorriso and GRUB
    log "  Building ISO image..."
    grub-mkrescue -o "$BUILD_DIR/arynox-os-$VERSION-$ARCH.iso" "$iso" \
        --xorriso=pxorriso \
        2>&1 | tail -5

    # Copy to release directory
    cp "$BUILD_DIR/arynox-os-$VERSION-$ARCH.iso" "$RELEASE_DIR/"

    local iso_size=$(du -h "$RELEASE_DIR/arynox-os-$VERSION-$ARCH.iso" | cut -f1)
    log "========================================================"
    log "ISO generated successfully!"
    log "  Path: $RELEASE_DIR/arynox-os-$VERSION-$ARCH.iso"
    log "  Size: $iso_size"
    log "  Version: $VERSION"
    log "  Arch: $ARCH"
    log "========================================================"
}

# ============================================================================
# Phase 9: Copy built artifacts back to Windows
# ============================================================================
phase_export() {
    log "Phase 9: Copying build artifacts to Windows..."

    local win_build="$PROJECT_DIR/release"
    mkdir -p "$win_build"

    cp "$BUILD_DIR/arynox-os-$VERSION-$ARCH.iso" "$win_build/" 2>/dev/null || true
    cp "$BUILD_DIR/vmlinuz-arynox" "$win_build/" 2>/dev/null || true
    cp "$BUILD_DIR/initramfs.img" "$win_build/" 2>/dev/null || true
    cp "$BUILD_DIR/filesystem.squashfs" "$win_build/" 2>/dev/null || true

    log "Artifacts exported to: $win_build"
    ls -lh "$win_build"
}

# ============================================================================
# Main build pipeline
# ============================================================================
main() {
    log "Arynox OS Build v$VERSION starting..."
    log "Architecture: $ARCH, Cores: $CORES"
    log "Build directory: $BUILD_DIR"
    echo ""

    cd "$PROJECT_DIR"

    # Parse arguments
    local phases="deps rust flutter python initramfs kernel squashfs iso export"
    if [ $# -gt 0 ]; then
        phases="$*"
    fi

    for phase in $phases; do
        case $phase in
            deps)       phase_install_deps ;;
            rust)       phase_build_rust ;;
            flutter)    phase_build_flutter ;;
            python)     phase_build_python ;;
            initramfs)  phase_initramfs ;;
            kernel)     phase_kernel ;;
            squashfs)   phase_squashfs ;;
            iso)        phase_iso ;;
            export)     phase_export ;;
            all)        phase_install_deps; phase_build_rust; phase_build_flutter;
                        phase_build_python; phase_initramfs; phase_kernel;
                        phase_squashfs; phase_iso; phase_export ;;
            *)          warn "Unknown phase: $phase" ;;
        esac
    done

    log "Build completed successfully!"
}

main "$@"
