#!/bin/bash

# Docker Build Scenarios for Cache Testing
# Various build commands to test different caching strategies

set -e

IMAGE_NAME="test-build-cache"
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${GREEN}🐳 Docker Build Scenarios${NC}"
echo "================================"

show_usage() {
    echo -e "${BLUE}Available scenarios:${NC}"
    echo ""
    echo "  basic          - Standard docker build"
    echo "  no-cache       - Build without using cache"  
    echo "  target         - Build specific stage only"
    echo "  buildkit       - Use BuildKit features"
    echo "  multi-platform - Multi-platform build"
    echo "  inline-cache   - Build with inline cache export"
    echo "  registry-cache - Use registry for cache"
    echo "  clean          - Clean up images and cache"
    echo "  all            - Run all scenarios"
    echo ""
    echo "Usage: $0 <scenario>"
}

basic_build() {
    echo -e "${YELLOW}📦 Basic Build${NC}"
    docker build -t $IMAGE_NAME .
}

no_cache_build() {
    echo -e "${YELLOW}🧹 No Cache Build${NC}"
    docker build --no-cache -t $IMAGE_NAME .
}

target_build() {
    echo -e "${YELLOW}🎯 Target Build (deps stage only)${NC}"
    docker build --target deps -t ${IMAGE_NAME}-deps .
}

buildkit_build() {
    echo -e "${YELLOW}🏗️ BuildKit Build${NC}"
    if docker buildx version >/dev/null 2>&1; then
        DOCKER_BUILDKIT=1 docker build -t $IMAGE_NAME .
    else
        echo "BuildKit not available, using standard build"
        docker build -t $IMAGE_NAME .
    fi
}

multi_platform_build() {
    echo -e "${YELLOW}🌍 Multi-platform Build${NC}"
    if docker buildx version >/dev/null 2>&1; then
        docker buildx build --platform linux/amd64,linux/arm64 -t $IMAGE_NAME .
    else
        echo "Buildx not available, skipping multi-platform build"
    fi
}

inline_cache_build() {
    echo -e "${YELLOW}💾 Inline Cache Build${NC}"
    if docker buildx version >/dev/null 2>&1; then
        docker buildx build \
            --cache-to type=inline \
            --cache-from $IMAGE_NAME \
            -t $IMAGE_NAME \
            --load .
    else
        echo "Buildx not available, using standard build"
        docker build -t $IMAGE_NAME .
    fi
}

registry_cache_build() {
    echo -e "${YELLOW}🏪 Registry Cache Build (simulated)${NC}"
    echo "Note: This would typically push/pull from a registry"
    if docker buildx version >/dev/null 2>&1; then
        docker buildx build \
            --cache-to type=local,dest=/tmp/docker-cache \
            --cache-from type=local,src=/tmp/docker-cache \
            -t $IMAGE_NAME \
            --load .
    else
        echo "Buildx not available, using standard build"
        docker build -t $IMAGE_NAME .
    fi
}

clean_up() {
    echo -e "${YELLOW}🧽 Cleaning up${NC}"
    echo "Removing test images..."
    docker rmi -f $IMAGE_NAME 2>/dev/null || true
    docker rmi -f ${IMAGE_NAME}-deps 2>/dev/null || true
    
    echo "Pruning build cache..."
    docker builder prune -f 2>/dev/null || true
    
    echo "Removing temporary cache..."
    rm -rf /tmp/docker-cache 2>/dev/null || true
    
    echo -e "${GREEN}✅ Cleanup complete${NC}"
}

run_all() {
    echo -e "${GREEN}🚀 Running all build scenarios${NC}"
    echo ""
    
    clean_up
    basic_build
    echo ""
    
    no_cache_build  
    echo ""
    
    target_build
    echo ""
    
    buildkit_build
    echo ""
    
    multi_platform_build
    echo ""
    
    inline_cache_build
    echo ""
    
    registry_cache_build
    echo ""
    
    echo -e "${GREEN}✅ All scenarios completed${NC}"
}

# Main script logic
case "${1:-}" in
    basic)
        basic_build
        ;;
    no-cache)
        no_cache_build
        ;;
    target)
        target_build
        ;;
    buildkit)
        buildkit_build
        ;;
    multi-platform)
        multi_platform_build
        ;;
    inline-cache)
        inline_cache_build
        ;;
    registry-cache)
        registry_cache_build
        ;;
    clean)
        clean_up
        ;;
    all)
        run_all
        ;;
    *)
        show_usage
        exit 1
        ;;
esac