source $(dirname "$0")/../.env

for pool in $(cat $CONFIG_FILE_PATH | jq -r '.[] | @base64'); do

    _jq() {
        echo ${pool} | base64 --decode | jq -r ${1}
    }
    uniswapV2Router=$(_jq '.uniswapV2Router')
    priceReader=$(_jq '.priceReader')
    tokenA=$(_jq '.tokenA.address')
    tokenB=$(_jq '.tokenB.address')
    symbolA=$(_jq '.tokenA.symbol')
    symbolB=$(_jq '.tokenB.symbol')
    maxSpentA=$(_jq '.tokenA.balance')
    maxSpentB=$(_jq '.tokenB.balance')

    echo "Testing sync condition on ($symbolA, $symbolB) pool"
    bash run/03-sync?.sh $uniswapV2Router $priceReader $tokenA $tokenB $symbolA $symbolB $maxSpentA $maxSpentB
done