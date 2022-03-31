#!/bin/bash
if [ -f .env ]; then
    # Load Environment Variables
    echo "✅ Loading environment variabled"
    export $(cat .env | grep -v '#' | sed 's/\r$//' | awk '/=/ {print $1}' )
else 
    echo "❌ Could not find .env file, rename .env.template and populate the file"
    exit 1
fi

if ! command -v caddy2 &> /dev/null 
then
    # Load Environment Variables
    echo "✅ Caddy is installed"
else 
    echo "❌ Could not find caddy"
    echo "Look at options here https://caddyserver.com/docs/install"
    if [[ $OSTYPE == 'darwin'* ]]; then
        echo "The easiest way to install caddy is using homebrew"
        echo "The command to install homebrew is here: https://brew.sh"
        echo "Once installed run brew install caddy"
    fi
    echo "Install Caddy"
    exit 1
fi

docker stop $CONTAINER_NAME
docker run \
    -d \
    -v venv_volume_$CONTAINER_NAME:/home/workspace/venv \
    -v dev_volume_$CONTAINER_NAME:/home/workspace/src \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -p $VSCODE_PORT:3000 \
    --name "${CONTAINER_NAME}" \
    "${CONTAINER_NAME}"
docker logs "${CONTAINER_NAME}"

caddy stop
caddy start --config caddy/Caddyfile_local
