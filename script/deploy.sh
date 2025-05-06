#!/bin/bash

# List of all networks to deploy on
NETWORKS=("sonicTestnet" "kairos" "electroneumTestnet" "basesepolia" "sepolia" "lisksepolia")

# Path to your Ignition module
MODULE_PATH="./ignition/modules/deploy.js"

# Loop through each network and deploy
for network in "${NETWORKS[@]}"
do
  echo "🔧 Deploying to $network..."
  if npx hardhat ignition deploy $MODULE_PATH --network "$network" --verify --reset --strategy create2; then
    echo "✅ Successfully deployed to $network"
  else
    echo "❌ Deployment failed on $network"
  fi
  echo "----------------------------------------"
done
