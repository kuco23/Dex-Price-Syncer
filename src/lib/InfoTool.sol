// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IUniswapV2Router} from "../interface/IUniswapV2Router.sol";
import {IPriceReader} from "../interface/IPriceReader.sol";
import {PriceCalc} from "../lib/PriceCalc.sol";


library InfoTool {

    function tokensToSwapForDexPriceSync(
        IUniswapV2Router _uniswapV2Router,
        IERC20Metadata _tokenA,
        IERC20Metadata _tokenB,
        uint256 _priceA,
        uint256 _priceB,
        uint256 _maxSwapA,
        uint256 _maxSwapB
    )
        internal view
        returns (uint256 _swapA, uint256 _swapB)
    {
        (uint256 reserveA, uint256 reserveB) = _uniswapV2Router.getReserves(address(_tokenA), address(_tokenB));
        uint8 decimalsA = _tokenA.decimals();
        uint8 decimalsB = _tokenB.decimals();
        (uint256 swapA, uint256 swapB) = PriceCalc.swapToDexPrice(reserveA, reserveB, _priceA, _priceB, decimalsA, decimalsB);
        return (_cap(swapA, _maxSwapA), _cap(swapB, _maxSwapB));
    }

    function liquidityToAddForDexPriceSync(
        IUniswapV2Router _uniswapV2Router,
        IERC20Metadata _tokenA,
        IERC20Metadata _tokenB,
        uint256 _priceA,
        uint256 _priceB,
        uint256 _maxAddedA,
        uint256 _maxAddedB
    )
        internal view
        returns (uint256, uint256)
    {
        (uint256 reserveA, uint256 reserveB) = safelyGetDexReserves(
            _uniswapV2Router, address(_tokenA), address(_tokenB));
        uint8 decimalsA = _tokenA.decimals();
        uint8 decimalsB = _tokenB.decimals();
        return PriceCalc.priceBasedAddedDexReserves(
            reserveA, reserveB, _priceA, _priceB, decimalsA, decimalsB, _maxAddedA, _maxAddedB);
    }

    function normalizedPrices(
        IPriceReader _priceReaderA,
        IPriceReader _priceReaderB,
        string memory _symbolA,
        string memory _symbolB
    )
        internal view
        returns (uint256 _priceA, uint256 _priceB)
    {
        (uint256 priceA,, uint256 priceDecimalsA) = _priceReaderA.getPrice(_symbolA);
        (uint256 priceB,, uint256 priceDecimalsB) = _priceReaderB.getPrice(_symbolB);
        return PriceCalc.normalizePrices(priceA, priceB, uint8(priceDecimalsA), uint8(priceDecimalsB));
    }

    function safelyGetDexReserves(
        IUniswapV2Router _uniswapV2,
        address _tokenA,
        address _tokenB
    )
        internal view
        returns (uint256, uint256)
    {
        try _uniswapV2.getReserves(_tokenA, _tokenB) returns (uint256 reserve0, uint256 reserve1) {
            return (reserve0, reserve1);
        } catch {
            return (0, 0);
        }
    }

    function _cap(uint256 _amount, uint256 _capAmount) private pure returns (uint256) {
        return _amount > _capAmount ? _capAmount : _amount;
    }
}