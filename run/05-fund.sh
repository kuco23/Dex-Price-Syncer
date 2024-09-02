source $(dirname "$0")/../.env

cast send $1 "transfer(address,uint256)" $DEX_PRICE_SYNCER_ADDRESS $2 --rpc-url $RPC_URL --broadcast