#!/bin/bash

show() {
  echo -e "\033[1;35m$1\033[0m"
}

if ! [ -x "$(command -v curl)" ]; then
  show "curl is not installed. Please install it to continue."
  exit 1
else
  show "curl is already installed."
fi
docker rm -f browser
# generate
IP=$(curl -s ifconfig.me)
USERNAME=$(< /dev/urandom tr -dc 'A-Za-z0-9' | head -c 5; echo)
PASSWORD=$(< /dev/urandom tr -dc 'A-Za-z0-9@#$&' | head -c 10; echo)

# backup userpass
CREDENTIALS_FILE="$HOME/vps-browser-credentials.json"
cat <<EOL > "$CREDENTIALS_FILE"
{
  "username": "$USERNAME",
  "password": "$PASSWORD"
}
EOL

show "Credentials generated:"
show "Username: $USERNAME"
show "Password: $PASSWORD"
show "Credentials saved to: $CREDENTIALS_FILE"

#  Proxy
show "============================================================="
show " Enter the proxy following format : user:password@host:port"
show "============================================================="
read -p "Enter Proxy: " PROXY_LINE

# select
PROXY_USER=$(echo "$PROXY_LINE" | cut -d':' -f1)
PROXY_PASS=$(echo "$PROXY_LINE" | cut -d':' -f2 | cut -d'@' -f1)
PROXY_HOST=$(echo "$PROXY_LINE" | cut -d'@' -f2 | cut -d':' -f1)
PROXY_PORT=$(echo "$PROXY_LINE" | cut -d':' -f3)

# details
show "============================================================="
show "Proxy details:"
show "Username: $PROXY_USER"
show "Password: $PROXY_PASS"
show "Host: $PROXY_HOST"
show "Port: $PROXY_PORT"
show "============================================================="

if ! [ -x "$(command -v docker)" ]; then
  show "Docker is not installed. Installing Docker..."
  curl -fsSL https://get.docker.com -o get-docker.sh
  sudo sh get-docker.sh
  if [ -x "$(command -v docker)" ]; then
    show "Docker installation was successful."
  else
    show "Docker installation failed."
    exit 1
  fi
else
  show "Docker is already installed."
fi


show "Pulling the latest Chromium Docker image..."
if ! sudo docker pull linuxserver/chromium:latest; then
  show "Failed to pull the Chromium Docker image."
  exit 1
else
  show "Successfully pulled the Chromium Docker image."
fi

#  config
mkdir -p "$HOME/chromium/config"

# Docker container
if [ "$(docker ps -q -f name=browser)" ]; then
  show "The Chromium Docker container is already running."
else
  show "Running Chromium Docker Container..."
  sudo docker run -d \
    --name browser \
    -e TITLE=Motza007 \
    -e DISPLAY=:1 \
    -e PUID=1000 \
    -e PGID=1000 \
    -e CUSTOM_USER="$USERNAME" \
    -e PASSWORD="$PASSWORD" \
    -e LANGUAGE=en_US.UTF-8 \
    -e http_proxy=http://$PROXY_USER:$PROXY_PASS@$PROXY_HOST:$PROXY_PORT \
    -e https_proxy=http://$PROXY_USER:$PROXY_PASS@$PROXY_HOST:$PROXY_PORT \
    -v "$HOME/chromium/config:/config" \
    -p 3000:3000 \
    -p 3001:3001 \
    --shm-size="4gb" \
    --restart unless-stopped \
    lscr.io/linuxserver/chromium:latest
  if [ $? -eq 0 ]; then
    show "Chromium Docker container started successfully."
  else
    show "Failed to start the Chromium Docker container."
  fi
fi


show "Click on this http://$IP:3000 or https://$IP:3001 to run the browser externally"
show "============================================================="
show "Input this username: $USERNAME in the browser"
show "Input this password: $PASSWORD in the browser"
show "============================================================="
show "Make sure to copy these credentials in order to access the browser externally. You can also get these credentials from $CREDENTIALS_FILE"

