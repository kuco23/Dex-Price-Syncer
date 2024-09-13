source $(dirname "$0")/../.env

uniswapV2Router=$1
priceReader=$2
tokenA=$3
tokenB=$4
symbolA=$5
symbolB=$6
maxSpentA=$7
maxSpentB=$8

ccall=$(
    cast send $DEX_PRICE_SYNCER_ADDRESS "sync(address,address,address,address,string,string,uint256,uint256)" \
        $uniswapV2Router $priceReader $tokenA $tokenB $symbolA $symbolB $maxSpentA $maxSpentB \
        --private-key $PRIVATE_KEY --rpc-url $RPC_URL
)

if echo "$ccall" | grep -q "(success)"; then
    echo "Syncing pool ($symbolA,$symbolB) succeeded"
else
    echo "Syncing pool ($symbolA,$symbolB) failed with error: $ccall"
fi