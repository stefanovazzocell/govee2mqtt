####################################################################################################
## Builder
####################################################################################################
FROM --platform=$BUILDPLATFORM rust:1.74-alpine AS builder

# Enable cross-compilation support
RUN apk add --no-cache musl-dev openssl-dev pkgconfig build-base git

# Create user (same as original)
RUN adduser \
    --disabled-password \
    --gecos "" \
    --home "/nonexistent" \
    --shell "/sbin/nologin" \
    --no-create-home \
    --uid "1000" \
    "govee"

# Set working directory
WORKDIR /build

# Copy all source code
COPY . .

# Build for release
RUN cargo build --release

WORKDIR /data

####################################################################################################
## Final image
####################################################################################################
FROM gcr.io/distroless/cc-debian12

# Import from builder.
COPY --from=builder /etc/passwd /etc/passwd
COPY --from=builder /etc/group /etc/group
#COPY --from=builder /etc/ssl/certs /etc/ssl/certs

WORKDIR /app

COPY --from=builder /build/target/release/govee /app/govee
COPY AmazonRootCA1.pem /app
COPY --from=builder --chown=govee:govee /data /data
COPY assets /app/assets

USER govee:govee
LABEL org.opencontainers.image.source="https://github.com/wez/govee2mqtt"
ENV \
  RUST_BACKTRACE=full \
  PATH=/app:$PATH \
  XDG_CACHE_HOME=/data

VOLUME /data

CMD ["/app/govee", \
  "serve", \
  "--govee-iot-key=/data/iot.key", \
  "--govee-iot-cert=/data/iot.cert", \
  "--amazon-root-ca=/app/AmazonRootCA1.pem"]
