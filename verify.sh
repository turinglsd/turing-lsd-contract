#!/bin/bash

# Set the verification parameters
RPC_URL="https://neoxt4seed1.ngd.network"
VERIFIER="blockscout"
VERIFIER_URL="https://xt4scan.ngd.network:8877/api"
FLATTEN_DIR="flattened_contracts"
JSON_DIR="json_inputs"

# Create directories to store the flattened contracts and JSON inputs
mkdir -p $FLATTEN_DIR $JSON_DIR

# Read JSON file for contract addresses
CONFIG_FILE="deployed_contract.json"
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: $CONFIG_FILE not found"
    exit 1
fi

# Parse JSON file for contract addresses
tuPHRS_ADDRESS=$(jq -r '."contract-address".tuPHRS' "$CONFIG_FILE")
WtuPHRS_ADDRESS=$(jq -r '."contract-address".WtuPHRS' "$CONFIG_FILE")
tuPHRS_NATIVE_MINTER_ADDRESS=$(jq -r '."contract-address".tuPHRSNativeMinter' "$CONFIG_FILE")
MOCK_NEO_ADDRESS=$(jq -r '."contract-address".MockNEO' "$CONFIG_FILE")
tuPHRS_ERC20_MINTER_ADDRESS=$(jq -r '."contract-address".tuPHRSERC20Minter' "$CONFIG_FILE")
TUBNEO_ADDRESS=$(jq -r '."contract-address".TuBNEO' "$CONFIG_FILE")
WTUBNEO_ADDRESS=$(jq -r '."contract-address".WtuBNEO' "$CONFIG_FILE")
MOCK_BNEO_ADDRESS=$(jq -r '."contract-address".MockBNEO' "$CONFIG_FILE")
TUBNEO_ERC20_MINTER_ADDRESS=$(jq -r '."contract-address".TuBNEOERC20Minter' "$CONFIG_FILE")
TUGAS_ADDRESS=$(jq -r '."contract-address".TuGAS' "$CONFIG_FILE")
WTUGAS_ADDRESS=$(jq -r '."contract-address".WtuGAS' "$CONFIG_FILE")
TUGAS_NATIVE_MINTER_ADDRESS=$(jq -r '."contract-address".TuGASNativeMinter' "$CONFIG_FILE")

# Function to compile, flatten, and verify a contract
compile_and_verify_contract() {
    local address=$1
    local contract_file=$2
    local contract_name=$3
    local solc_version="0.8.17" # Ensure this matches your contract's version
    local json_output="$JSON_DIR/${contract_name}_standard.json"
    local max_retries=3
    local retry_delay=10

    if [ -z "$address" ] || [ "$address" == "null" ]; then
        echo "Skipping verification for $contract_name: Address not provided"
        return
    fi

    # Compile the contract to generate the standard JSON input
    echo "Compiling $contract_name with solc to generate standard JSON input..."
    if solc --optimize --combined-json abi,bin,bin-runtime,srcmap,srcmap-runtime,metadata "$contract_file" -o "$JSON_DIR" --overwrite; then
        echo "Standard JSON input generated successfully: $json_output"
    else
        echo "Error compiling $contract_name. Check the file path: $contract_file"
        return 1
    fi

    # Verify the contract
    echo "Verifying $contract_name at address $address"

    for ((i = 1; i <= max_retries; i++)); do
        if forge verify-contract \
            --rpc-url "$RPC_URL" \
            --verifier "$VERIFIER" \
            --verifier-url "$VERIFIER_URL" \
            "$address" \
            "$contract_file:$contract_name"; then
            echo "Verification successful for $contract_name"
            return 0
        else
            echo "Attempt $i failed. Retrying in $retry_delay seconds..."
            sleep $retry_delay
        fi
    done

    echo "Failed to verify $contract_name after $max_retries attempts"
    return 1
}

echo "Using RPC URL: $RPC_URL"
echo "Using Verifier: $VERIFIER"
echo "Using Verifier URL: $VERIFIER_URL"

# Compile and verify contracts
compile_and_verify_contract "$tuPHRS_ADDRESS" "src/tokens/tuPHRS.sol" "tuPHRS"
compile_and_verify_contract "$WtuPHRS_ADDRESS" "src/staking/wtuPHRS.sol" "WtuPHRS"
compile_and_verify_contract "$tuPHRS_NATIVE_MINTER_ADDRESS" "src/minters/tuPHRSMinter.sol" "NativeMinterWithdrawal"
compile_and_verify_contract "$MOCK_NEO_ADDRESS" "src/tokens/tuPHRS.sol" "MERC20"
compile_and_verify_contract "$tuPHRS_ERC20_MINTER_ADDRESS" "src/minters/tuPHRSMinter.sol" "ERC20MinterWithdrawal"
compile_and_verify_contract "$TUBNEO_ADDRESS" "src/tokens/tuBNEO.sol" "TuBNEO"
compile_and_verify_contract "$WTUBNEO_ADDRESS" "src/staking/wtuBNEO.sol" "WtuBNEO"
compile_and_verify_contract "$MOCK_BNEO_ADDRESS" "src/tokens/tuPHRS.sol" "MERC20"
compile_and_verify_contract "$TUBNEO_ERC20_MINTER_ADDRESS" "src/minters/tuPHRSMinter.sol" "ERC20MinterWithdrawal"
compile_and_verify_contract "$TUGAS_ADDRESS" "src/tokens/tuGAS.sol" "TuGAS"
compile_and_verify_contract "$WTUGAS_ADDRESS" "src/staking/wtuGAS.sol" "WtuGAS"
compile_and_verify_contract "$TUGAS_NATIVE_MINTER_ADDRESS" "src/minters/tuPHRSMinter.sol" "NativeMinterWithdrawal"

echo "Verification process completed. Compiler run successful. Artifact(s) can be found in directory 'json_inputs'."
