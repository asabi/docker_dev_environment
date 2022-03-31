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
caddy stop