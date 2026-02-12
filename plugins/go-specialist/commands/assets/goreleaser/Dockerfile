# Multi-stage Dockerfile for Go applications
# Creates minimal, secure container images using scratch base
# CUSTOMIZE: Replace PROJECT_BINARY and PROJECT_USER with your values

# Stage 1: Get CA certificates from Alpine
# Required for HTTPS connections from scratch-based images
FROM alpine:3.22 AS alpine

# Stage 2: Create minimal runtime image
FROM scratch AS final

# Set working directory for the application
WORKDIR /usr/local/bin

# Copy the compiled binary from GoReleaser build context
# CUSTOMIZE: Replace PROJECT_BINARY with your binary name (must match project_name in .goreleaser.yml)
COPY PROJECT_BINARY .

# Copy CA certificates for HTTPS/TLS connections
# Required for APIs, webhooks, external services
COPY --from=alpine /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

# Copy additional resources (config files, static assets, etc.)
# CUSTOMIZE: Remove if your application doesn't need additional files
COPY "resources" /

# Run as non-root user for security
# CUSTOMIZE: Replace PROJECT_USER with your application's username (must match resources/etc/passwd)
USER PROJECT_USER

# Define volumes for persistent data and temporary files
# CUSTOMIZE: Adjust paths based on your application's needs
VOLUME [ "/data", "/tmp" ]

# Optional: Expose ports
# CUSTOMIZE: Uncomment and set the port your application listens on
# EXPOSE 8080

# Optional: Set default command
# CUSTOMIZE: Uncomment and adjust if you want a default command/entrypoint
# ENTRYPOINT ["PROJECT_BINARY"]
# CMD ["--help"]

# Optional: Health check
# CUSTOMIZE: Uncomment and adjust for your application's health endpoint
# HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
#   CMD ["/usr/local/bin/PROJECT_BINARY", "healthcheck"]

# Image metadata
# These labels are automatically set by GoReleaser:
# - org.opencontainers.image.created
# - org.opencontainers.image.title
# - org.opencontainers.image.revision
# - org.opencontainers.image.version
# - org.opencontainers.image.source
