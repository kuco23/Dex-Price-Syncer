// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;


library PriceCalc {

    uint256 constant PRICE_PRECISION_DECIMALS = 18;
    uint256 constant PRICE_PRECISION = 10 ** PRICE_PRECISION_DECIMALS;

    function priceBasedAddedDexReserves(
        uint256 _initialReserveA,
        uint256 _initialReserveB,
        uint256 _priceA,
        uint256 _priceB,
        uint8 _decimalsA,
        uint8 _decimalsB,
        uint256 _maxAddedA,
        uint256 _maxAddedB
    ) public pure returns (uint256, uint256) {
        (uint256 ratioB, uint256 ratioA) = relativeUnitPriceMulDiv(_priceA, _priceB, _decimalsA, _decimalsB);
        uint256 optimalAddedA = _maxAddedA;
        uint256 optimalAddedB = (_initialReserveA + optimalAddedA) * ratioB / ratioA - _initialReserveB;
        if (optimalAddedB > _maxAddedB) {
            optimalAddedB = _maxAddedB;
            optimalAddedA = (_initialReserveB + optimalAddedB) * ratioA / ratioB - _initialReserveA;
            if (optimalAddedA > _maxAddedA) {
                return (0, 0);
            }
        }
        return (optimalAddedA, optimalAddedB);
    }

    /**
     * Numerical unit price of tokenA in tokenB shifted by `PRICE_PRECISION_DECIMALS` decimals
     * @param _tokenPriceA - price of tokenA (e.g. BTC) in any currency x (e.g. USD)
     * @param _tokenPriceB - price of tokenB (e.g. XRP) in any currency x (e.g. USD)
     * @param _decimalsA - decimals of tokenA (e.g. 8)
     * @param _decimalsB - decimals of tokenB (e.g. 6)
     */
    function relativeUnitPrice(
        uint256 _tokenPriceA, uint256 _tokenPriceB,
        uint8 _decimalsA, uint8 _decimalsB
    )
        public pure
        returns (uint256)
    {
        (uint256 mul, uint256 div) = relativeUnitPriceMulDiv(_tokenPriceA, _tokenPriceB, _decimalsA, _decimalsB);
        return relativePrice(mul, div);
    }

    /**
     * Token price of tokenA in tokenB, given the reserves of tokenA and tokenB
     * @param _reserveA - reserve of tokenA
     * @param _reserveB - reserve of tokenB
     * @param _decimalsA - decimals of tokenA
     * @param _decimalsB - decimals of tokenB
     */
    function relativeTokenDexPrice(
        uint256 _reserveA, uint256 _reserveB,
        uint8 _decimalsA, uint8 _decimalsB
    )
        public pure
        returns (uint256)
    {
        return relativeUnitPrice(_reserveB, _reserveA, _decimalsB, _decimalsA);
    }

    /**
     * Theoretical unit price of tokenA in tokenB (e.g. 1 Satoshi = 10000 / 2 XrpDrops)
     * @param _tokenPriceA - price of tokenA (e.g. BTC) in any currency x (e.g. USD)
     * @param _tokenPriceB - price of tokenB (e.g. XRP) in any currency x (e.g. USD)
     * @param _decimalsA - decimals of tokenA (e.g. 8)
     * @param _decimalsB - decimals of tokenB (e.g. 6)
     * @return mul - multiplier of the calculated unit price
     * @return div - divisor of the calculated unit price
     */
    function relativeUnitPriceMulDiv(
        uint256 _tokenPriceA, uint256 _tokenPriceB,
        uint8 _decimalsA, uint8 _decimalsB
    )
        public pure
        returns (uint256, uint256)
    {
        return (
            _tokenPriceA * 10 ** _decimalsB,
            _tokenPriceB * 10 ** _decimalsA
        );
    }

    /**
     * Numerical price of tokenA in tokenB shifted by `PRICE_PRECISION_DECIMALS` decimals
     * @param _priceA - price of tokenA (e.g. BTC) in any currency x (e.g. USD)
     * @param _priceB - price of tokenB (e.g. XRP) in any currency x (e.g. USD)
     */
    function relativePrice(
        uint256 _priceA, uint256 _priceB
    )
        public pure
        returns (uint256)
    {
        return PRICE_PRECISION * _priceA / _priceB;
    }


}