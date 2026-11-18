
#!/bin/bash

set -e

echo "================================"
echo " Ubuntu 24.04 - Docker-in-Docker"
echo "================================"

mkdir -p /var/run /var/lib/docker

echo "[Docker] Starting dockerd..."

dockerd \
    --host=unix:///var/run/docker.sock \
    --data-root=/var/lib/docker \
    --storage-driver="${DOCKER_STORAGE_DRIVER:-overlay2}" \
    --iptables=true &

DOCKER_PID=$!

echo "[Docker] Waiting for Docker Engine..."

READY=0

for i in $(seq 1 60); do
    if docker info >/dev/null 2>&1; then
        READY=1
        break
    fi

    if ! kill -0 "$DOCKER_PID" 2>/dev/null; then
        echo "[Docker] Daemon exited unexpectedly."
        exit 1
    fi

    sleep 1
done

if [ "$READY" -ne 1 ]; then
    echo "[Docker] Docker startup timeout."
    exit 1
fi

echo "[Docker] Engine ready!"

docker version
docker compose version

echo "[Application] Starting Node.js..."

exec node index.js
