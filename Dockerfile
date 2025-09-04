######
# 🛠️ Builder Stages
######

# 📄 Tool Builder 1 - Simulates building a custom tool (like Ghostscript)
FROM ubuntu:22.04 AS tool-builder-1
RUN echo "🔧 Setting up Tool Builder 1..."
RUN apt-get update && \
  apt-get -y -qq --no-install-recommends install \
  build-essential wget ca-certificates tar && \
  rm -rf /var/lib/apt/lists/*

WORKDIR /usr/src/tools
# Simulate downloading and building a tool
RUN echo "📥 Downloading simulated tool..." && \
  mkdir -p custom-tool-1 && \
  echo '#!/bin/bash\necho "Custom Tool 1 v1.0.0 - Processing: $@"' > custom-tool-1/tool1 && \
  chmod +x custom-tool-1/tool1

RUN echo "🏗️ Building Tool 1..." && \
  sleep 2 && \
  echo "✅ Tool 1 build complete"

# 📚 Tool Builder 2 - Simulates building another custom tool (like MuPDF)
FROM ubuntu:22.04 AS tool-builder-2
RUN echo "🔧 Setting up Tool Builder 2..."
RUN apt-get update && \
  apt-get -y -qq --no-install-recommends install \
  build-essential git ca-certificates && \
  rm -rf /var/lib/apt/lists/*

WORKDIR /usr/src/tools
# Simulate building another tool
RUN echo "📥 Cloning simulated tool repository..." && \
  mkdir -p custom-tool-2 && \
  echo '#!/bin/bash\necho "Custom Tool 2 v2.1.0 - Processing: $@"' > custom-tool-2/tool2 && \
  chmod +x custom-tool-2/tool2

RUN echo "🏗️ Building Tool 2..." && \
  sleep 3 && \
  echo "✅ Tool 2 build complete"

######
# 📦 Dependencies Stage - Node.js base for dependency installation
######
FROM node:18-slim AS deps
RUN echo "📦 Setting up dependency installation..."

WORKDIR /usr/src/app

# Copy package files for dependency installation
COPY package.json package-lock.json ./

# Install dependencies
RUN echo "📚 Installing Node.js dependencies..." && \
  npm ci --omit=dev && \
  npm cache clean --force

######
# 🏗️ Build Stage - Compile TypeScript
######
FROM node:18-slim AS builder
RUN echo "🏗️ Setting up build environment..."

WORKDIR /usr/src/app

# Copy package files
COPY package.json package-lock.json tsconfig.json ./

# Install all dependencies (including dev dependencies)
RUN echo "📚 Installing all dependencies for build..." && \
  npm ci

# Copy source code
COPY src/ ./src/

# Build the application
RUN echo "🔨 Building TypeScript application..." && \
  npm run build && \
  echo "✅ Build complete"

######
# 🎭 Final Runtime Image
######
FROM node:18-slim
RUN echo "🎭 Setting up final runtime image..."

# 📦 Package Management - Install production tools
RUN echo "📦 Installing system utilities..." && \
  apt-get update && \
  apt-get -y -qq --no-install-recommends install \
  tini curl && \
  rm -rf /var/lib/apt/lists/*

# 👤 User Setup - Creating non-root user for security
RUN echo "👤 Creating non-root user for enhanced security..." && \
  groupadd -r appuser && \
  useradd -r -g appuser -G audio,video appuser && \
  mkdir -p /home/appuser && \
  chown -R appuser:appuser /home/appuser

# 📂 Workspace Setup
WORKDIR /usr/src/app

# 📄 Custom Tools - Copy built tools from builder stages
RUN echo "📄 Installing custom tools..."
COPY --from=tool-builder-1 --chown=appuser:appuser /usr/src/tools/custom-tool-1/tool1 /usr/local/bin/tool1
COPY --from=tool-builder-2 --chown=appuser:appuser /usr/src/tools/custom-tool-2/tool2 /usr/local/bin/tool2

# Test that tools work
RUN echo "🧪 Testing custom tools..." && \
  tool1 test && \
  tool2 test && \
  echo "✅ Custom tools installed successfully"

# 📚 Dependencies - Copy from deps stage
COPY --from=deps --chown=appuser:appuser /usr/src/app/node_modules ./node_modules

# 🏗️ Built Application - Copy from builder stage
COPY --from=builder --chown=appuser:appuser /usr/src/app/dist ./dist
COPY --from=builder --chown=appuser:appuser /usr/src/app/package.json ./package.json

# 🔒 Security Setup - Setting permissions
RUN echo "🔒 Setting appropriate file permissions..." && \
  chown -R appuser:appuser /usr/src/app

# ⚡ Initialize Tini as PID 1
ENTRYPOINT ["/usr/bin/tini", "--"]

# 👤 User Switch
RUN echo "👤 Switching to non-root user..."
USER appuser

# 🌐 Expose port
EXPOSE 3000

# 🚀 Application Startup
RUN echo "🚀 Ready to launch application..."
ENV NODE_ENV=production
ENV NODE_OPTIONS="--max-old-space-size=1024"

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:3000/health || exit 1

CMD ["node", "dist/index.js"]