#!/bin/bash

# Load environment variables from .env file
if [ -f .env ]; then
  echo "Loading .env..."
  export $(grep -v '^#' .env | xargs)
else
  echo ".env file not found! Exiting..."
  exit 1
fi

# Run Makefile targets one after the other
echo "Starting deployments..."

make deploy-sepolia || { echo "deploy-sepolia failed"; exit 1; }
make deploy-blaze || { echo "deploy-blaze failed"; exit 1; }
# make runner-blaze || { echo "runner-blaze failed"; exit 1; }
make deploy-base-sepolia || { echo "deploy-base-sepolia failed"; exit 1; }
make deploy-lisk-sepolia || { echo "deploy-lisk-sepolia failed"; exit 1; }
make deploy-kairos || { echo "deploy-kairos failed"; exit 1; }

echo "✅ All deployments completed successfully!"
