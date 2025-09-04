#!/bin/bash

# Docker Build Cache Testing Script
# This script demonstrates different Docker caching scenarios

set -e

IMAGE_NAME="test-build-cache"
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}🐳 Docker Build Cache Testing Script${NC}"
echo "=================================================="

# Function to measure build time
time_build() {
    local build_type="$1"
    local extra_args="$2"
    echo -e "${YELLOW}📊 Testing: $build_type${NC}"
    echo "Command: docker build $extra_args -t $IMAGE_NAME ."
    echo ""
    
    start_time=$(date +%s)
    docker build $extra_args -t $IMAGE_NAME .
    end_time=$(date +%s)
    
    duration=$((end_time - start_time))
    echo -e "${GREEN}✅ $build_type completed in ${duration}s${NC}"
    echo ""
    return $duration
}

# Test 1: Clean build (no cache)
echo -e "${YELLOW}🧹 Test 1: Clean build (no cache)${NC}"
time_build "Clean build" "--no-cache"
clean_time=$?

# Test 2: Rebuild with full cache
echo -e "${YELLOW}🚀 Test 2: Rebuild with full cache${NC}"
time_build "Cached build" ""
cached_time=$?

# Test 3: Modify source code and rebuild (should cache deps but rebuild app)
echo -e "${YELLOW}🔧 Test 3: Modify source code${NC}"
echo "// Cache test modification at $(date)" >> src/routes.ts
time_build "Source code change" ""
source_change_time=$?

# Test 4: Modify package.json (should invalidate dependency cache)
echo -e "${YELLOW}📦 Test 4: Modify package.json${NC}"
# Add a comment to package.json to trigger cache invalidation
cp package.json package.json.backup
echo '  "comment": "cache test modification",' >> package.json
time_build "Dependency change" ""
deps_change_time=$?

# Restore package.json
mv package.json.backup package.json

# Test 5: BuildKit features test
if docker buildx version >/dev/null 2>&1; then
    echo -e "${YELLOW}🏗️ Test 5: BuildKit with cache mount${NC}"
    time_build "BuildKit build" "--builder=buildx"
    buildkit_time=$?
else
    echo -e "${RED}⚠️ BuildKit not available, skipping test 5${NC}"
    buildkit_time=0
fi

# Results summary
echo -e "${GREEN}📈 RESULTS SUMMARY${NC}"
echo "=================================================="
printf "%-25s %10s\n" "Build Type" "Time (s)"
echo "------------------------------------------"
printf "%-25s %10s\n" "Clean build" "${clean_time}s"
printf "%-25s %10s\n" "Full cache" "${cached_time}s"
printf "%-25s %10s\n" "Source change" "${source_change_time}s"
printf "%-25s %10s\n" "Deps change" "${deps_change_time}s"
if [ $buildkit_time -gt 0 ]; then
    printf "%-25s %10s\n" "BuildKit" "${buildkit_time}s"
fi

# Calculate cache efficiency
if [ $clean_time -gt 0 ]; then
    cache_efficiency=$(( (clean_time - cached_time) * 100 / clean_time ))
    echo ""
    echo -e "${GREEN}🎯 Cache efficiency: ${cache_efficiency}%${NC}"
fi

echo ""
echo -e "${GREEN}✅ Cache testing complete!${NC}"
echo -e "${YELLOW}💡 Tips:${NC}"
echo "  - Full cache builds should be significantly faster"
echo "  - Source changes should only rebuild final stages"  
echo "  - Dependency changes should rebuild from deps layer"
echo "  - Use 'docker system df' to see cache usage"