#!/bin/sh

if hash docker 2>/dev/null; then
    echo "✅ Docker is installed"
else
    echo "❌ Docker is not installed"
    exit 1
fi
if hash docker-compose 2>/dev/null; then
    echo "✅ Docker Compose is installed"
else
    echo "❌ Docker compose is not installed"
    exit 1
fi

docker-compose  up -d --force-recreate
