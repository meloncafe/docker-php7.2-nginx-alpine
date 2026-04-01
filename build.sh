#!/usr/bin/env bash
set -euo pipefail

IMAGE_NAME="devsaurus/alpine-nginx-php"
TAG="${1:-7.4}"
FULL_IMAGE="${IMAGE_NAME}:${TAG}"

echo "=== Building ${FULL_IMAGE} ==="
docker build -t "${FULL_IMAGE}" .

echo ""
echo "=== Verifying PHP version ==="
docker run --rm "${FULL_IMAGE}" php -v

echo ""
echo "=== Verifying mysqlnd (caching_sha2_password support) ==="
docker run --rm "${FULL_IMAGE}" php -r "echo 'mysqlnd: ' . phpversion('mysqlnd') . PHP_EOL;"

echo ""
echo "=== Verifying installed extensions ==="
docker run --rm "${FULL_IMAGE}" php -m | grep -iE "pdo|mysql|openssl"

echo ""
read -p "Push ${FULL_IMAGE} to Docker Hub? [y/N] " confirm
if [[ "${confirm}" =~ ^[Yy]$ ]]; then
    docker push "${FULL_IMAGE}"

    # 7-latest 태그도 함께 업데이트
    docker tag "${FULL_IMAGE}" "${IMAGE_NAME}:7-latest"
    docker push "${IMAGE_NAME}:7-latest"

    echo ""
    echo "=== Pushed ==="
    echo "  ${FULL_IMAGE}"
    echo "  ${IMAGE_NAME}:7-latest"
else
    echo "Skipped push. Run manually:"
    echo "  docker push ${FULL_IMAGE}"
fi
