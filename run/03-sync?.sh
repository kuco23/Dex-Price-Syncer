source $(dirname "$0")/../.env

MAX_PRICE_DIFF=10000000000000 # PRICE_PRECISION / 1e5
PRICE_PRECISION_TO_BIPS=10000000000000

uniswapV2Router=$1
priceReader=$2
tokenA=$3
tokenB=$4
symbolA=$5
symbolB=$6
maxSpentA=$7
maxSpentB=$8

formatDiff() {
    echo $(expr $1 '/' $PRICE_PRECISION_TO_BIPS)
}

diff=$(
    cast call $DEX_PRICE_SYNCER_ADDRESS "dexRelativeTokenPriceDiff(address,address,address,address,string,string)(uint256)" \
        $uniswapV2Router $priceReader $tokenA $tokenB $symbolA $symbolB --rpc-url $RPC_URL
)

if [[ $(expr "$diff" '>' $MAX_PRICE_DIFF) ]]; then
    echo "Syncing pool ($symbolA,$symbolB) with price diff $(formatDiff $diff) BIPS"
    ./run/02-sync.sh $uniswapV2Router $priceReader $tokenA $tokenB $symbolA $symbolB $maxSpentA $maxSpentB
    echo "Ended syncing pool ($symbolA,$symbolB)"
else
    echo "Pool ($symbolA,$symbolB) is synced with price diff $(formatDiff $diff) BIPS"
fi