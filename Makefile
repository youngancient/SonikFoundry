# Load .env file
include .env
export $(shell sed 's/=.*//' .env)

# Deploy to Sepolia
deploy-sepolia:
	@forge script script/deploy.s.sol:SoniKDeployer \
		--rpc-url $(SEPOLIA_RPC_URL) \
		--private-key $(private_key) \
		--etherscan-api-key $(ETHERSCAN_API_KEY) \
		--verify \
		--broadcast

deploy-blaze:
	@forge script script/deploy.s.sol:SoniKDeployer \
		--rpc-url $(BLAZE_RPC_URL) \
		--private-key $(private_key) \
		--etherscan-api-key $(ETHERSCAN_API_KEY) \
		--verify \
		--broadcast
		

# Deploy to Base Sepolia
deploy-base-sepolia:
	@forge script script/deploy.s.sol:SoniKDeployer \
		--rpc-url $(BASE_SEPOLIA_RPC_URL) \
		--private-key $(private_key) \
		--etherscan-api-key $(BASESCAN_API_KEY) \
		--verify \
		--broadcast

# Deploy to Lisk Sepolia
deploy-lisk-sepolia:
	@forge script script/deploy.s.sol:SoniKDeployer \
		--rpc-url $(Lisk_SEPOLIA_RPC_URL) \
		--etherscan-api-key 123 \
		--verify \
		--verifier blockscout \
		--verifier-url https://sepolia-blockscout.lisk.com/api \
		--private-key $(private_key) \
		--broadcast

# Deploy to Kairos
deploy-kairos:
	@forge script script/deploy.s.sol:SoniKDeployer \
		--rpc-url $(KAIA_RPC_URL) \
		--chain-id 1001 \
		--verifier sourcify \
		--verifier-url https://sourcify.dev/server/ \
		--private-key $(private_key) \
		--broadcast \
		--verify
