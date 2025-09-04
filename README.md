# Docker Build Cache Test Application

A simple Node.js application designed to test Docker build caching strategies using multi-stage builds.

## 🎯 Purpose

This application demonstrates various Docker caching optimization techniques:

- **Multi-stage builds** with separate builder stages
- **Dependency layer caching** by copying package files before source code
- **Build artifact separation** using dedicated build stages
- **Layer optimization** with strategic COPY ordering

## 🏗️ Architecture

The Dockerfile uses a multi-stage build approach:

```
┌─────────────────┐    ┌─────────────────┐
│  Tool Builder 1 │    │  Tool Builder 2 │
│  (Ubuntu 22.04) │    │  (Ubuntu 22.04) │
└─────────────────┘    └─────────────────┘
         │                       │
         └───────────┬───────────┘
                     │
          ┌─────────────────┐
          │  Dependencies   │
          │  (Node 18-slim) │
          └─────────────────┘
                     │
          ┌─────────────────┐
          │     Builder     │
          │  (Node 18-slim) │
          └─────────────────┘
                     │
          ┌─────────────────┐
          │  Final Runtime  │
          │  (Node 18-slim) │
          └─────────────────┘
```

### Build Stages

1. **tool-builder-1 & tool-builder-2**: Simulate building custom tools (like Ghostscript/MuPDF)
2. **deps**: Install only production dependencies
3. **builder**: Install all dependencies and compile TypeScript
4. **final**: Combine everything for the runtime image

## 🚀 Quick Start

### Build the Application

```bash
# Basic build
npm run docker:build

# Build without cache
npm run docker:build-no-cache

# Run the container
npm run docker:run
```

### Test Caching Strategies

```bash
# Run comprehensive cache testing
npm run docker:test-cache

# Or use the script directly
./scripts/test-cache.sh
```

### Build Scenarios

```bash
# Test different build scenarios
./scripts/build-scenarios.sh all

# Available scenarios:
./scripts/build-scenarios.sh basic          # Standard build
./scripts/build-scenarios.sh no-cache       # No cache build  
./scripts/build-scenarios.sh target         # Build specific stage
./scripts/build-scenarios.sh buildkit       # BuildKit features
./scripts/build-scenarios.sh inline-cache   # Inline cache
./scripts/build-scenarios.sh clean          # Cleanup
```

## 🎯 Caching Optimization Points

### 1. **Dependency Caching**
```dockerfile
# Copy package files first (changes less frequently)
COPY package.json package-lock.json* ./
RUN npm ci --only=production

# Copy source code later (changes more frequently)  
COPY src/ ./src/
```

### 2. **Multi-stage Separation**
- **Builder stages**: Heavy compilation steps cached separately
- **Dependencies stage**: Node modules cached independently  
- **Final stage**: Only runtime artifacts

### 3. **Layer Ordering**
- System packages first
- Dependencies second  
- Application code last
- Most frequently changed files at the bottom

### 4. **BuildKit Features**
```bash
# Cache mounts
RUN --mount=type=cache,target=/root/.npm npm ci

# Inline cache
docker buildx build --cache-to type=inline
```

## 📊 Testing Cache Efficiency

The test script measures build times across scenarios:

- **Clean build**: No cache, full rebuild
- **Cached build**: Full cache utilization
- **Source change**: Only final stages rebuild
- **Dependency change**: Invalidates dependency cache

### Expected Results

| Scenario | Expected Behavior |
|----------|------------------|
| Clean build | ~60-120s (downloads, builds tools) |
| Full cache | ~5-15s (all layers cached) |
| Source change | ~20-30s (rebuilds from source copy) |
| Deps change | ~45-60s (rebuilds from package install) |

## 🔍 Cache Analysis Commands

```bash
# View Docker cache usage
docker system df

# Inspect build history  
docker history test-build-cache

# View layer details
docker buildx imagetools inspect test-build-cache

# Prune build cache
docker builder prune
```

## 📁 Project Structure

```
test-build-cache/
├── src/
│   ├── index.ts          # Main Express server
│   ├── config.ts         # Configuration
│   └── routes.ts         # API routes
├── scripts/
│   ├── test-cache.sh     # Cache testing script
│   └── build-scenarios.sh # Build scenario runner
├── Dockerfile            # Multi-stage build
├── .dockerignore        # Docker ignore rules
├── package.json         # Dependencies
├── tsconfig.json        # TypeScript config
└── README.md           # This file
```

## 🌐 API Endpoints

Once running (on port 3000):

- `GET /` - Application info and links
- `GET /health` - Health check endpoint  
- `GET /info` - Detailed system information
- `GET /simulate/cpu` - CPU-intensive task simulation
- `GET /simulate/memory` - Memory allocation simulation
- `GET /simulate/io` - I/O delay simulation

## 💡 Cache Optimization Tips

1. **Order Dockerfile instructions** by frequency of change
2. **Use .dockerignore** to exclude unnecessary files
3. **Separate dependency installation** from source code copying
4. **Leverage multi-stage builds** for clean separation
5. **Use BuildKit features** for advanced caching
6. **Pin versions** to ensure consistent builds
7. **Consider cache mounts** for package managers

## 🧪 Experiment Ideas

Try these modifications to see cache behavior:

1. **Add a new dependency** to package.json
2. **Change a source file** in src/
3. **Modify the Dockerfile** instruction order
4. **Add/remove files** from .dockerignore
5. **Change build arguments** or environment variables

## 📈 Monitoring Cache Performance

```bash
# Time builds
time docker build -t test-build-cache .

# Monitor cache usage
watch -n 1 'docker system df'

# Analyze layer sizes
docker history test-build-cache --format "table {{.CreatedBy}}\t{{.Size}}"
```

---

Happy Docker caching! 🐳✨