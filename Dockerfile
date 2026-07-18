# Stage 1: Build Arynox OS
FROM ubuntu:24.04 AS builder

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C
ENV RUSTUP_HOME=/opt/rust
ENV CARGO_HOME=/opt/cargo
ENV PATH="/opt/cargo/bin:/opt/flutter/bin:$PATH"

# Install system dependencies
RUN apt-get update -qq && apt-get install -y -qq \
    debootstrap squashfs-tools xorriso grub-pc mtools \
    parted dosfstools \
    curl wget ca-certificates git build-essential \
    pkg-config libssl-dev \
    python3 python3-pip python3-requests \
    clang cmake ninja-build \
    libgtk-3-dev liblzma-dev \
    && rm -rf /var/lib/apt/lists/*

# Install Rust
RUN curl --proto =https --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y \
    && rustup default stable

# Install Flutter
RUN wget -q https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.44.6-stable.tar.xz \
    && tar xf flutter_linux_3.44.6-stable.tar.xz -C /opt \
    && rm flutter_linux_3.44.6-stable.tar.xz \
    && flutter config --enable-linux-desktop

WORKDIR /build

# Copy source
COPY . .

# Build Rust daemons
RUN cargo build --release 2>&1 || echo "Rust build incomplete"

# Build Flutter apps
RUN for dir in src/*/ src/ai/*/; do \
        if [ -f "$dir/pubspec.yaml" ]; then \
            echo "Building $(basename $dir)..." && \
            cd "$dir" && flutter pub get && flutter build linux --release 2>&1 || true && \
            cd /build; \
        fi; \
    done

# Build root filesystem
RUN bash scripts/build-full-os.sh 2>&1

# Build USB image
RUN bash scripts/build-usb-image.sh 2>&1

# Compress and split artifacts for GitHub Releases (<2GB per chunk)
RUN mkdir -p /output && \
    if [ -f build/arynox-usb.img ]; then \
        split -b 1900M build/arynox-usb.img /output/arynox-os-0.1.0-amd64.img.part; \
        cp build/filesystem.squashfs /output/ && \
        cp build/vmlinuz-* /output/ 2>/dev/null || true; \
        cp build/initramfs.img /output/ 2>/dev/null || true; \
    fi

FROM scratch
COPY --from=builder /output/ /
