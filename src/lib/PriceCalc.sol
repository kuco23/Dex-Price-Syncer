// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Babylonian} from "./Babylonian.sol";


library PriceCalc {

    uint256 constant PRICE_PRECISION_DECIMALS = 18;
    uint256 constant PRICE_PRECISION = 10 ** PRICE_PRECISION_DECIMALS;

    // uniswap-v2 constants
    uint256 constant DEX_FEE_BIPS = 3;
    uint256 constant DEX_MAX_BIPS = 1000;
    uint256 constant DEX_FACTOR_BIPS = DEX_MAX_BIPS - DEX_FEE_BIPS;

    /**
     * The amount of tokenA to swap to achieve the desired price
     * @param _initialReserveA - initial dex reserve of tokenA
     * @param _initialReserveB - initial dex reserve of tokenB
     * @param _priceA - price of tokenA in any currency x
     * @param _priceB - price of tokenB in any currency x
     * @param _decimalsA - decimals of tokenA
     * @param _decimalsB - decimals of tokenB
     */
    function swapToDexPrice(
        uint256 _initialReserveA,
        uint256 _initialReserveB,
        uint256 _priceA,
        uint256 _priceB,
        uint8 _decimalsA,
        uint8 _decimalsB
    )
        internal pure
        returns (uint256 _swapA, uint256 _swapB)
    {
        (uint256 priceABMul, uint256 priceABDiv) = relativeUnitPriceMulDiv(_priceA, _priceB, _decimalsA, _decimalsB);
        return _swapToDexPrice(_initialReserveA, _initialReserveB, priceABMul, priceABDiv);
    }

    /**
     * The amount of tokenA and tokenB to add to the dex to achieve the desired price
     * @param _initialReserveA - initial dex reserve of tokenA
     * @param _initialReserveB - initial dex reserve of tokenB
     * @param _priceA - price of tokenA in any currency x
     * @param _priceB - price of tokenB in any currency x
     * @param _decimalsA - decimals of tokenA
     * @param _decimalsB - decimals of tokenB
     * @param _maxAddedA - maximum amount of tokenA to add to the dex
     * @param _maxAddedB - maximum amount of tokenB to add to the dex
     * @return _optimalAddedA - optimal amount of tokenA to add to the dex
     * @return _optimalAddedB - optimal amount of tokenB to add to the dex
     */
    function priceBasedAddedDexReserves(
        uint256 _initialReserveA,
        uint256 _initialReserveB,
        uint256 _priceA,
        uint256 _priceB,
        uint8 _decimalsA,
        uint8 _decimalsB,
        uint256 _maxAddedA,
        uint256 _maxAddedB
    )
        internal pure
        returns (uint256 _optimalAddedA, uint256 _optimalAddedB)
    {
        (uint256 ratioB, uint256 ratioA) = relativeUnitPriceMulDiv(_priceA, _priceB, _decimalsA, _decimalsB);
        return _ratioBasedAddedDexReserves(_initialReserveA, _initialReserveB, ratioA, ratioB, _maxAddedA, _maxAddedB);
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
        internal pure
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
        internal pure
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
        internal pure
        returns (uint256, uint256)
    {
        return (
            _tokenPriceA * 10 ** _decimalsB,
            _tokenPriceB * 10 ** _decimalsA
        );
    }

    /**
     * Numerical price of asset A in asset B shifted by `PRICE_PRECISION_DECIMALS` decimals
     * @param _priceA - price of asset A (e.g. Satoshi) in any currency x (e.g. USD)
     * @param _priceB - price of asset B (e.g. XRP) in any currency x (e.g. USD)
     */
    function relativePrice(
        uint256 _priceA, uint256 _priceB
    )
        internal pure
        returns (uint256)
    {
        return PRICE_PRECISION * _priceA / _priceB;
    }

    /**
     * Normalizes two prices so they share the same number of decimals
     * @param _priceA - price of tokenA
     * @param _priceB - price of tokenB
     * @param _priceDecimalsA - decimals of priceA
     * @param _priceDecimalsB - decimals of priceB
     */
    function conormalizePrices(
        uint256 _priceA, uint256 _priceB,
        uint8 _priceDecimalsA, uint8 _priceDecimalsB
    )
        internal pure
        returns (uint256, uint256)
    {
        if (_priceDecimalsA > _priceDecimalsB) {
            _priceB *= 10**(_priceDecimalsA - _priceDecimalsB);
        } else if (_priceDecimalsA < _priceDecimalsB) {
            _priceA *= 10**(_priceDecimalsB - _priceDecimalsA);
        }
        return (_priceA, _priceB);
    }

    function _ratioBasedAddedDexReserves(
        uint256 _initialReserveA,
        uint256 _initialReserveB,
        uint256 _ratioA,
        uint256 _ratioB,
        uint256 _maxAddedA,
        uint256 _maxAddedB
    )
        private pure
        returns (uint256, uint256)
    {
        uint256 optimalAddedA = _maxAddedA;
        uint256 optimalAddedB = (_initialReserveA + optimalAddedA) * _ratioB / _ratioA - _initialReserveB;
        if (optimalAddedB > _maxAddedB) {
            optimalAddedB = _maxAddedB;
            optimalAddedA = (_initialReserveB + optimalAddedB) * _ratioA / _ratioB - _initialReserveA;
            if (optimalAddedA > _maxAddedA) {
                return (0, 0);
            }
        }
        return (optimalAddedA, optimalAddedB);
    }

    function _swapToDexPrice(
        uint256 _initialReserveA,
        uint256 _initialReserveB,
        uint256 _priceABMul,
        uint256 _priceABDiv
    )
        private pure
        returns (uint256 _swapA, uint256 _swapB)
    {
        (uint256 swapA, bool okA) = _swapToDexRatio(_initialReserveA, _initialReserveB, _priceABDiv, _priceABMul);
        (uint256 swapB,) = okA ? _swapToDexRatio(_initialReserveB, _initialReserveA, _priceABMul, _priceABDiv) : (0, true);
        return (swapA, swapB);
    }

    function _swapToDexRatio(
        uint256 _initialReserveA,
        uint256 _initialReserveB,
        uint256 _desiredRatioA,
        uint256 _desiredRatioB
    )
        private pure
        returns (uint256 _swapA, bool _negative)
    {
        uint256 aux1 = 4 * _initialReserveB * _desiredRatioA * DEX_FACTOR_BIPS / DEX_MAX_BIPS;
        uint256 aux2 = _initialReserveA * _desiredRatioB * (DEX_MAX_BIPS - DEX_FACTOR_BIPS) ** 2 / DEX_MAX_BIPS ** 2;
        uint256 aux3 = Babylonian.sqrt(_initialReserveA * (aux1 + aux2) / _desiredRatioB);
        uint256 aux4 = _initialReserveA * (DEX_FACTOR_BIPS + DEX_MAX_BIPS) / DEX_MAX_BIPS;
        if (aux3 < aux4) return (0, true);
        return ((aux3 - aux4) * (DEX_MAX_BIPS / 2 * DEX_FACTOR_BIPS), false);
    }

}