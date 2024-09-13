source $(dirname "$0")/../.env

to=$1

for pool in $(cat $CONFIG_FILE_PATH | jq -r '.[] | @base64'); do

    _jq() {
        echo ${pool} | base64 --decode | jq -r ${1}
    }
    tokenA=$(_jq '.tokenA.address')
    tokenB=$(_jq '.tokenB.address')
    uniswapV2Router=$(_jq '.uniswapV2Router')

    cast send $DEX_PRICE_SYNCER_ADDRESS "withdrawPool(address,address,address,address)" $uniswapV2Router $tokenA $tokenB $to --rpc-url $RPC_URL --private-key $PRIVATE_KEY
done

cast send $DEX_PRICE_SYNCER_ADDRESS "withdrawNative(address)" $to --rpc-url $RPC_URL --private-key $PRIVATE_KEY