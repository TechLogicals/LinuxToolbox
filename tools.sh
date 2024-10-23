#!/bin/bash
echo "Grabbing LinuxToolbox..."
# Repository URL
REPO_URL="https://github.com/techlogicals/linuxtoolbox.git"
# Clone the repository
git clone "$REPO_URL"

# Extract the repository name from the URL
REPO_NAME=$(basename "$REPO_URL" .git)

# Change directory to the cloned repository
cd "$REPO_NAME" || exit

# Run the linuxrtoolbox script
./linuxtoolbox
