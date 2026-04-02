#!/usr/bin/env bash
set -euo pipefail

IMAGE_NAME="devsaurus/alpine-nginx-php"
TAG="${1:-7.4}"
FULL_IMAGE="${IMAGE_NAME}:${TAG}"
PLATFORMS="linux/amd64,linux/arm64"

# buildx builder 확인/생성
BUILDER_NAME="multiarch"
if ! docker buildx inspect "${BUILDER_NAME}" &>/dev/null; then
    echo "=== Creating buildx builder: ${BUILDER_NAME} ==="
    docker buildx create --name "${BUILDER_NAME}" --use
else
    docker buildx use "${BUILDER_NAME}"
fi

echo "=== Building ${FULL_IMAGE} (${PLATFORMS}) ==="
echo ""
read -p "Build and push to Docker Hub? [y/N] " confirm
if [[ "${confirm}" =~ ^[Yy]$ ]]; then
    docker buildx build --platform "${PLATFORMS}" -t "${FULL_IMAGE}" --push .
    echo ""
    echo "=== Pushed: ${FULL_IMAGE} ==="
    echo "=== Platforms: ${PLATFORMS} ==="
else
    # 로컬 빌드만 (현재 아키텍처)
    docker buildx build --platform "${PLATFORMS}" -t "${FULL_IMAGE}" --load . 2>/dev/null || {
        echo "Multi-arch --load not supported. Building for current platform only."
        docker build -t "${FULL_IMAGE}" .
    }
fi

echo ""
echo "=== Verifying PHP version ==="
docker run --rm "${FULL_IMAGE}" php -v

echo ""
echo "=== Verifying mysqlnd ==="
docker run --rm "${FULL_IMAGE}" php -r "echo 'mysqlnd: ' . phpversion('mysqlnd') . PHP_EOL;"

echo ""
echo "=== Verifying extensions ==="
docker run --rm "${FULL_IMAGE}" php -m | grep -iE "pdo|mysql|openssl"
