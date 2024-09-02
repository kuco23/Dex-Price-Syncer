source $(dirname "$0")/../.env

forge create src/DexPriceSyncer.sol:DexPriceSyncer --private-key $PRIVATE_KEY --rpc-url $RPC_URL