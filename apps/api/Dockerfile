FROM golang:1.23.7-alpine AS builder

# Install build dependencies for static linking and security
RUN apk add --no-cache \
  ca-certificates \
  git

WORKDIR /build

# Copy go mod files for better Docker layer caching
COPY go.mod go.sum ./
RUN go mod download

# Copy source code
COPY . .

# Build main API binary with optimizations for size and security
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build \
  -a -installsuffix cgo \
  -ldflags='-w -s -extldflags "-static"' \
  -o api main.go

FROM gcr.io/distroless/static:nonroot

# Import CA certificates from builder (required for HTTPS OAuth calls)
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

# Note: Timezone data not copied - app uses UTC timestamps
# Add this line if you need timezone parsing: 
# COPY --from=builder /usr/share/zoneinfo /usr/share/zoneinfo

# Copy binaries from build stage
COPY --from=builder /build/api /api

# Use non-root user for security
USER nonroot:nonroot

# Health checks handled externally (e.g., Docker Compose, Kubernetes, load balancer)
# External tools can call: GET http://container:8080/health

# Default port
EXPOSE 8080

# Default command runs the API server
ENTRYPOINT ["/api"]
