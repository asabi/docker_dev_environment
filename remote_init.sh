#!/bin/bash
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

docker stop dev # In case running from local
docker rm dev # In case running from local
if hash caddy 2>/dev/null; then
    # Load Environment Variables
    echo "✅ Caddy is locally installed -> Stopping caddy in case it runs"
    caddy stop
fi
docker-compose build --force-rm
docker-compose  up -d --force-recreate
rm -Rf ./git.pem
docker-compose logs | grep "secret"
echo "Done Script"
