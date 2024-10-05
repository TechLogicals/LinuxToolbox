#!/bin/bash

# Update package list and install prerequisites
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common

# Add Docker's official GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

# Add Docker repository
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

# Update package list again
sudo apt-get update

# Install Docker
sudo apt-get install -y docker-ce docker-ce-cli containerd.io

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Add current user to docker group
sudo usermod -aG docker $USER

# Create a directory for Restreamer
mkdir -p ~/restreamer
cd ~/restreamer

# Ask user for RS_USERNAME and RS_PASSWORD
read -p "Enter username for Restreamer: " RS_USERNAME
read -sp "Enter password for Restreamer: " RS_PASSWORD
echo

# Ask user for input source and output target
read -p "Enter input source (e.g., rtsp://192.168.1.123:554/stream1) or press Enter to skip: " RS_INPUTSOURCE
read -p "Enter output target (e.g., rtmp://live.youtube.com/live2/xxxx-xxxx-xxxx-xxxx) or press Enter to skip: " RS_OUTPUTTARGET

# Create docker-compose.yml file for Restreamer
cat << EOF > docker-compose.yml
version: '3.7'

services:
  restreamer:
    image: datarhei/restreamer:latest
    restart: always
    ports:
      - 8080:8080
    volumes:
      - ./config:/core/config
      - ./data:/core/data
    devices:
      - /dev/dri:/dev/dri
    environment:
      - RS_USERNAME=$RS_USERNAME
      - RS_PASSWORD=$RS_PASSWORD
      - RS_AUTH=true
EOF

# Add input source and output target to docker-compose.yml if provided
if [ ! -z "$RS_INPUTSOURCE" ]; then
    echo "      - RS_INPUTSOURCE=$RS_INPUTSOURCE" >> docker-compose.yml
fi
if [ ! -z "$RS_OUTPUTTARGET" ]; then
    echo "      - RS_OUTPUTTARGET=$RS_OUTPUTTARGET" >> docker-compose.yml
fi

# Add network configuration to docker-compose.yml
cat << EOF >> docker-compose.yml

networks:
  default:
    driver: bridge
EOF

# Start Restreamer
docker-compose up -d

echo "Restreamer has been installed and started. Access it at http://localhost:8080"
echo "Username: $RS_USERNAME"
echo "You may need to log out and log back in for docker commands to work without sudo."


