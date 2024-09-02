source $(dirname "$0")/../.env

for pool in $(cat $CONFIG_FILE_PATH | jq -r '.[] | @base64'); do

    _jq() {
        echo ${pool} | base64 --decode | jq -r ${1}
    }
    tokenA=$(_jq '.tokenA.address')
    tokenB=$(_jq '.tokenB.address')

    forge cast send $DEX_PRICE_SYNCER_ADDRESS "withdrawToken(address,address)" $tokenA $ADDRESS --rpc-url $RPC_URL --broadcast
    forge cast send $DEX_PRICE_SYNCER_ADDRESS "withdrawToken(address,address)" $tokenB $ADDRESS --rpc-url $RPC_URL --broadcast
done

forge cast send $DEX_PRICE_SYNCER_ADDRESS "withdrawNative(address)" $ADDRESS --rpc-url $RPC_URL --broadcast