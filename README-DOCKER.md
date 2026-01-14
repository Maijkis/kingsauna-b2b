# 🐳 Docker Setup for Kingsauna Landing Page

This project is containerized using Docker and nginx to serve the static landing page and survey.

## 📋 Prerequisites

- Docker installed on your system
- Docker Compose (optional, but recommended)

## 🚀 Quick Start

### Option 1: Using Docker Compose (Recommended)

```bash
# Build and start the container
docker-compose up -d

# View logs
docker-compose logs -f

# Stop the container
docker-compose down
```

The site will be available at: **http://localhost:8080**

### Option 2: Using Docker directly

```bash
# Build the image
docker build -t kingsauna-landing .

# Run the container
docker run -d -p 8080:80 --name kingsauna-landing kingsauna-landing

# View logs
docker logs -f kingsauna-landing

# Stop the container
docker stop kingsauna-landing
docker rm kingsauna-landing
```

## 🔧 Configuration

### Port Configuration

To change the port, edit `docker-compose.yml`:
```yaml
ports:
  - "YOUR_PORT:80"  # Change YOUR_PORT to desired port
```

Or with Docker directly:
```bash
docker run -d -p YOUR_PORT:80 --name kingsauna-landing kingsauna-landing
```

### Nginx Configuration

The nginx configuration is in `nginx.conf`. Key features:
- Gzip compression enabled
- Static asset caching (1 year)
- Security headers
- Health check endpoint at `/health`

## 📦 What's Included

The Docker image includes:
- `index.html` - Landing page
- `survey.html` - Survey page
- `analytics-tracker.js` - Analytics tracking
- `images/` - All image assets
- nginx web server

## 🏥 Health Check

The container includes a health check endpoint:
```bash
curl http://localhost:8080/health
# Returns: healthy
```

## 🔍 Troubleshooting

### Container won't start
```bash
# Check logs
docker logs kingsauna-landing

# Check if port is already in use
lsof -i :8080
```

### Files not updating
```bash
# Rebuild the image
docker-compose build --no-cache

# Or with Docker directly
docker build --no-cache -t kingsauna-landing .
```

### Permission issues
```bash
# Make sure Docker has proper permissions
sudo usermod -aG docker $USER
# Then log out and back in
```

## 🚢 Production Deployment

### Build for production
```bash
docker build -t kingsauna-landing:latest .
```

### Tag for registry
```bash
docker tag kingsauna-landing:latest your-registry/kingsauna-landing:latest
```

### Push to registry
```bash
docker push your-registry/kingsauna-landing:latest
```

### Deploy to server
```bash
docker pull your-registry/kingsauna-landing:latest
docker run -d -p 80:80 --name kingsauna-landing --restart unless-stopped your-registry/kingsauna-landing:latest
```

## 📝 Notes

- The container runs nginx on port 80 internally
- External port is configurable (default: 8080)
- All static files are served with proper caching headers
- Health check runs every 30 seconds
