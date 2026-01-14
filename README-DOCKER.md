# 🐳 Docker Setup for Kingsauna Landing Page

This project is containerized using Docker and nginx to serve the static landing page and survey.

## 🚀 Automated Build (GitHub Actions)

**The Docker image is automatically built and pushed to GitHub Container Registry on every push to `main` branch.**

### Using the Pre-built Image

The image is available at: `ghcr.io/akseler/kingsauna:latest`

```bash
# Pull and run the pre-built image
docker pull ghcr.io/akseler/kingsauna:latest
docker run -d -p 8080:80 --name kingsauna-landing ghcr.io/akseler/kingsauna:latest
```

### View Build Status

Check the [Actions tab](https://github.com/Akseler/kingsauna/actions) in your GitHub repository to see build status.

---

## 📋 Local Development Prerequisites

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

### Option 1: Use Pre-built Image from GitHub Container Registry (Recommended)

```bash
# Pull the latest image
docker pull ghcr.io/akseler/kingsauna:latest

# Run on production server
docker run -d -p 80:80 --name kingsauna-landing --restart unless-stopped ghcr.io/akseler/kingsauna:latest
```

### Option 2: Build Locally and Push

```bash
# Build for production
docker build -t kingsauna-landing:latest .

# Tag for GitHub Container Registry
docker tag kingsauna-landing:latest ghcr.io/akseler/kingsauna:latest

# Login to GitHub Container Registry
echo $GITHUB_TOKEN | docker login ghcr.io -u USERNAME --password-stdin

# Push to registry
docker push ghcr.io/akseler/kingsauna:latest
```

### Option 3: Deploy to Other Registries

```bash
# Tag for your registry
docker tag kingsauna-landing:latest your-registry/kingsauna-landing:latest

# Push to registry
docker push your-registry/kingsauna-landing:latest
```

## 📝 Notes

- The container runs nginx on port 80 internally
- External port is configurable (default: 8080)
- All static files are served with proper caching headers
- Health check runs every 30 seconds
