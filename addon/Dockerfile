# syntax=docker/dockerfile:1

# Supervisor injects this; declare before any FROM that uses it
ARG BUILD_FROM

# ---------- build stage: compile your fork on Debian (glibc) ----------
FROM --platform=$BUILDPLATFORM rust:1.82-bookworm AS build

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
    ca-certificates git pkg-config libssl-dev build-essential \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /src

# hardcode your repo + branch/tag; no build args, no ../
RUN git clone --depth 1 --branch v0.0.10 \
    https://github.com/AlekseyBlokhin/govee2mqtt-f . \
    || (echo "Failed to clone your fork" && exit 1)

# build the release binary (Cargo.lock v4 is supported in this toolchain)
RUN cargo build --release

# ---------- final stage: Home Assistant base image ----------
FROM $BUILD_FROM
WORKDIR /app

# copy compiled binary + runtime assets
COPY --from=build /src/target/release/govee /app/govee
COPY --from=build /src/AmazonRootCA1.pem /app/
COPY --from=build /src/assets /app/assets

# entrypoint from the add-on context (present in addon/)
COPY run.sh /run.sh

CMD ["/run.sh"]
