# 🐳 Docker Deployment Guide

## Container Architecture

The A la carte REST API uses a **multi-stage Docker build** for maximum security and minimal image size:

- **Build Stage**: Full Go toolchain (golang:1.23.7-alpine) for compilation
- **Runtime Stage**: Google's distroless static image (no shell, package managers, or unnecessary binaries)
- **Image Size**: ~15MB (vs ~300MB+ with standard Go images)
- **Security**: Minimal attack surface, non-root user, static binary linking

## Quick Start

```bash
# 1. Build the Docker image
docker build -t alacarte-api .

# 2. Run migrations (one-time setup)
docker run --env-file .env alacarte-api /migrate

# 3. Seed database (optional, for development data)
docker run --env-file .env alacarte-api /seed

# 4. Start the API server
docker run -p 8080:8080 --env-file .env alacarte-api
```

## Production Deployment

### Using Docker Compose

```bash
# 1. Create production environment file
cp .env.prod.template .env.prod
# Update environment variables in docker-compose.prod.yml to include seeding
# RUN_SEEDING=true
# CHEESE_DATA_SOURCE=https://raw.githubusercontent.com/username/alacarte-data/main/cheeses.json

# 2. Start database
docker-compose -f docker-compose.prod.yml up -d mysql

# 3. Wait for MySQL to be ready, then run migrations
docker-compose -f docker-compose.prod.yml --profile migrate up migrate

# 4. Seed database (optional)
docker-compose -f docker-compose.prod.yml --profile seed up seed

# 5. Start API service
docker-compose -f docker-compose.prod.yml up -d api
```

### Complete Setup Script

```bash
#!/bin/bash
# deploy.sh - Complete production deployment

set -e

echo "🚀 Deploying A la carte REST API..."

# Build image
docker-compose -f docker-compose.prod.yml build

# Start database
echo "📊 Starting MySQL database..."
docker-compose -f docker-compose.prod.yml up -d mysql

# Wait for MySQL to be healthy
echo "⏳ Waiting for database to be ready..."
docker-compose -f docker-compose.prod.yml --profile migrate up --wait mysql

# Run migrations
echo "🏗️ Running database migrations..."
docker-compose -f docker-compose.prod.yml --profile migrate up migrate

# Seed database (optional)
echo "🌱 Seeding database..."
docker-compose -f docker-compose.prod.yml --profile seed up seed

# Start API
echo "🌐 Starting API service..."
docker-compose -f docker-compose.prod.yml up -d api

echo "✅ Deployment complete! API available at http://localhost:8080"
echo "🔍 Health check: curl http://localhost:8080/health"
```

## Security Features

### Minimal Attack Surface
- **Distroless base image**: No shell, package managers, or debugging tools
- **Non-root user**: Runs as `nonroot` user (UID 65532)
- **Static binary**: No dynamic library dependencies
- **Minimal filesystem**: Only essential files included

### Build Security
- **Multi-stage build**: Source code not included in final image
- **Static linking**: `CGO_ENABLED=0` prevents C library dependencies
- **Build optimizations**: `-ldflags='-w -s'` strips debug info and symbol tables
- **CA certificates**: Included for HTTPS OAuth calls

### Runtime Security
```dockerfile
# Non-root user execution
USER nonroot:nonroot

# No built-in health check - handled externally for maximum security
# External tools can call: GET http://container:8080/health

# Minimal file permissions
COPY --from=builder /build/api /api
```

## Binary Usage

The Docker image contains three binaries:

### API Server
```bash
# Default entrypoint
docker run alacarte-api
# Equivalent to: docker run alacarte-api /api
```

### Database Migrations
```bash
# Run migrations
docker run --env-file .env alacarte-api /migrate

# Example environment variables needed:
# DB_HOST=mysql
# DB_PORT=3306  
# DB_NAME=alacarte
# DB_USER=alacarte
# DB_PASSWORD=your-password
```

### Database Seeding
```bash
# Seed with development data
docker run --env-file .env alacarte-api /seed

# Requires same database environment variables as migrations
# Creates OAuth test users and sample cheese/rating data
```

## Environment Configuration

### Required Variables
```env
# Database (MySQL)
MYSQL_HOST=mysql
MYSQL_PORT=3306
MYSQL_DATABASE=alacarte
MYSQL_USERNAME=alacarte
MYSQL_PASSWORD=your-secure-password

# Authentication
JWT_SECRET_KEY=your-64-char-secret-key
```

### Optional Variables
```env
# Server
GIN_MODE=release
TRUSTED_PROXIES=10.0.0.0/8,172.16.0.0/12,192.168.0.0/16
ALLOWED_ORIGINS=https://yourdomain.com

# Development
MOCK_OAUTH=false
```

## Health Monitoring

### External Health Monitoring
```bash
# Check container status (no built-in health check)
docker ps

# Manual health check via HTTP
curl http://localhost:8080/health

# Using Docker Compose with external health checker
docker-compose -f docker-compose.prod.yml --profile monitoring up -d healthchecker
docker-compose -f docker-compose.prod.yml logs -f healthchecker
```

### Kubernetes Health Probes
```yaml
livenessProbe:
  httpGet:
    path: /health
    port: 8080
  initialDelaySeconds: 30
  periodSeconds: 10

readinessProbe:
  httpGet:
    path: /health
    port: 8080
  initialDelaySeconds: 5
  periodSeconds: 5
```

## Performance Optimization

### Image Size Optimization
- **Distroless base**: ~15MB vs 300MB+ standard images
- **Static binary**: No dynamic library dependencies
- **Build optimizations**: Debug symbols stripped
- **Multi-stage build**: Only essential files in final image

### Runtime Performance
- **MySQL tuning**: Custom my.cnf with optimized buffer sizes
- **Connection pooling**: GORM handles database connections efficiently
- **Health check caching**: Lightweight endpoint for monitoring

## Troubleshooting

### Common Issues

**Connection Refused**
```bash
# Check if database is ready
docker-compose -f docker-compose.prod.yml ps

# View logs
docker-compose -f docker-compose.prod.yml logs mysql
docker-compose -f docker-compose.prod.yml logs api
```

**Migration Failures**
```bash
# Check database connection
docker run --env-file .env --entrypoint="" alacarte-api /migrate

# Manual database connection test
docker exec -it mysql-container mysql -u alacarte -p alacarte
```

**Permission Errors**
```bash
# Distroless images run as nonroot user
# Ensure no volume mounts require root access
```

### Debug Mode

For debugging, you can override the entrypoint:

```bash
# Use debug container with shell (development only)
docker run -it --entrypoint="" golang:1.23.7-alpine sh

# Or run with debug info (not recommended for production)
docker build --build-arg LDFLAGS="-w" -t alacarte-api-debug .
```

## Monitoring & Logging

### Container Logs
```bash
# Follow API logs
docker-compose -f docker-compose.prod.yml logs -f api

# Follow all service logs
docker-compose -f docker-compose.prod.yml logs -f
```

### Performance Monitoring
```bash
# Container resource usage
docker stats

# Detailed container info
docker inspect alacarte-api
```

### Log Aggregation (Production)
```yaml
# docker-compose.prod.yml
services:
  api:
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
```

## Scaling & Load Balancing

### Horizontal Scaling
```yaml
# docker-compose.prod.yml
services:
  api:
    deploy:
      replicas: 3
    ports:
      - "8080-8082:8080"
```

### Load Balancer Configuration
```nginx
upstream alacarte_api {
    server localhost:8080;
    server localhost:8081;
    server localhost:8082;
}

server {
    location / {
        proxy_pass http://alacarte_api;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

---

**🔒 Security Note**: Always use the distroless production image in production environments. The minimal attack surface significantly reduces security risks compared to standard base images.
