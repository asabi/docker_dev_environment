#!/bin/bash
if hash docker 2>/dev/null; then
    echo "✅ Docker is installed"
else
    echo "❌ Docker is not installed"
    exit 1
fi
if [ -f .env ]; then
    # Load Environment Variables
    echo "✅ Loading environment variabled"
    export $(cat .env | grep -v '#' | sed 's/\r$//' | awk '/=/ {print $1}' )
else 
    echo "❌ Could not find .env file, rename .env.template and populate the file"
    exit 1
fi

if [ -f "$GIT_SSH_KEY" ]; then
    echo "✅ Copying GIT SSH key file to ${PWD}"
    cp "${GIT_SSH_KEY}" ./git.pem
    
else 
    echo "❌ $GIT_SSH_KEY does not exist, exiting setup."
    exit 1
fi

docker build \
    --build-arg email=$GIT_EMAIL \
    --build-arg name=$GIT_NAME \
    --build-arg sls_key=$SERVERLESS_KEY \
    -t $CONTAINER_NAME \
    .
docker stop $CONTAINER_NAME
docker rm $CONTAINER_NAME
docker run \
    -d \
    -v venv_volume_$CONTAINER_NAME:/home/workspace/venv \
    -v dev_volume_$CONTAINER_NAME:/home/workspace/src \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -p $VSCODE_PORT:3000 \
    --name "${CONTAINER_NAME}" \
    "${CONTAINER_NAME}"
docker logs "${CONTAINER_NAME}"
rm -Rf ./git.pem
