FROM ubuntu:24.04 AS base

RUN apt-get update && apt-get install -y \
    build-essential \
    curl \
    git \
    pkg-config \
    libwayland-dev \
    libxkbcommon-dev \
    libegl1-mesa-dev \
    libgles2-mesa-dev \
    libdbus-1-dev \
    libsystemd-dev \
    libudev-dev \
    libinput-dev \
    libdrm-dev \
    libgbm-dev \
    libseat-dev \
    python3 \
    python3-pip \
    python3-venv \
    && rm -rf /var/lib/apt/lists/*

FROM base AS rust-builder

RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"

WORKDIR /build
COPY Cargo.toml Cargo.lock ./
COPY core/ ./core/
COPY src/wm/ ./src/wm/
COPY src/files/ ./src/files/
COPY src/devices/ ./src/devices/
COPY src/packages/ ./src/packages/
COPY src/security/ ./src/security/
COPY src/cloud/ ./src/cloud/
COPY src/devtools/ ./src/devtools/
COPY src/updates/ ./src/updates/
COPY src/network/ ./src/network/

RUN cargo build --release --workspace

FROM base AS python-builder

WORKDIR /build
COPY ai-python/ ./ai-python/
RUN pip install poetry && cd ai-python && poetry build

FROM ubuntu:24.04 AS runtime

RUN apt-get update && apt-get install -y \
    libwayland-client0 \
    libxkbcommon0 \
    libegl1 \
    libgles2 \
    libdbus-1-3 \
    libsystemd0 \
    libudev1 \
    libinput10 \
    libdrm2 \
    libgbm1 \
    libseat1 \
    python3 \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

COPY --from=rust-builder /build/target/release/arynox-session /usr/lib/arynox/
COPY --from=rust-builder /build/target/release/arynox-compositor /usr/lib/arynox/
COPY --from=rust-builder /build/target/release/arynox-tpm /usr/lib/arynox/
COPY --from=rust-builder /build/target/release/arynox-boot-check /usr/lib/arynox/
COPY --from=rust-builder /build/target/release/arynox-device-manager /usr/lib/arynox/
COPY --from=rust-builder /build/target/release/arynox-package-manager /usr/lib/arynox/
COPY --from=rust-builder /build/target/release/arynox-security /usr/lib/arynox/
COPY --from=rust-builder /build/target/release/arynox-cloud /usr/lib/arynox/
COPY --from=rust-builder /build/target/release/arynox-devtools /usr/lib/arynox/
COPY --from=rust-builder /build/target/release/arynox-updates /usr/lib/arynox/
COPY --from=rust-builder /build/target/release/arynox-installer /usr/lib/arynox/
COPY --from=rust-builder /build/target/release/arynox-recovery /usr/lib/arynox/

COPY --from=python-builder /build/ai-python/dist/*.whl /tmp/
RUN pip install /tmp/*.whl

COPY src/boot/systemd/*.service /usr/lib/systemd/system/

RUN mkdir -p /etc/arynox /var/lib/arynox

CMD ["/usr/lib/arynox/arynox-session"]
