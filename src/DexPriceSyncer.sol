// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IERC20Metadata, IERC20} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IUniswapV2Router} from "./interface/IUniswapV2Router.sol";
import {IPriceReader} from "./interface/IPriceReader.sol";
import {InfoTool} from "./lib/InfoTool.sol";


contract DexPriceSyncer is Ownable {

    constructor() Ownable(msg.sender) {}

    function dexRelativeTokenPriceDiff(
        IUniswapV2Router _uniswapV2Router,
        IPriceReader _priceReader,
        IERC20Metadata _tokenA,
        IERC20Metadata _tokenB,
        string memory _symbolA,
        string memory _symbolB
    )
        external view
        returns (uint256)
    {
        (uint256 priceA, uint256 priceB) = InfoTool.conormalizedPrices(_priceReader, _symbolA, _symbolB);
        return InfoTool.dexRelativeTokenPriceDiff(_uniswapV2Router, _tokenA, _tokenB, priceA, priceB);
    }

    function sync(
        IUniswapV2Router _uniswapV2Router,
        IPriceReader _priceReader,
        IERC20Metadata _tokenA,
        IERC20Metadata _tokenB,
        string memory _symbolA,
        string memory _symbolB,
        uint256 _maxSpentA,
        uint256 _maxSpentB
    )
        external
        onlyOwner
    {
        _maxSpentA = _capWithBalance(_tokenA, address(this), _maxSpentA);
        _maxSpentB = _capWithBalance(_tokenB, address(this), _maxSpentB);
        (uint256 reserveA,) = InfoTool.safelyGetDexReserves(_uniswapV2Router, address(_tokenA), address(_tokenB));
        if (reserveA == 0) {
            addLiquidityToSyncDexPrice(
                _uniswapV2Router, _priceReader, _tokenA, _tokenB, _symbolA, _symbolB, _maxSpentA, _maxSpentB);
        } else {
            swapToSyncDexPrice(
                _uniswapV2Router, _priceReader, _tokenA, _tokenB, _symbolA, _symbolB, _maxSpentA, _maxSpentB);
        }
    }

    function addLiquidityToSyncDexPrice(
        IUniswapV2Router _uniswapV2Router,
        IPriceReader _priceReader,
        IERC20Metadata _tokenA,
        IERC20Metadata _tokenB,
        string memory _symbolA,
        string memory _symbolB,
        uint256 _maxAddedA,
        uint256 _maxAddedB
    )
        public
        onlyOwner
    {
        (uint256 priceA, uint256 priceB) = InfoTool.conormalizedPrices(_priceReader, _symbolA, _symbolB);
        (uint256 addedA, uint256 addedB) = InfoTool.liquidityToAddForDexPriceSync(
            _uniswapV2Router, _tokenA, _tokenB, priceA, priceB, _maxAddedA, _maxAddedB);
        _addLiquidity(_uniswapV2Router, IERC20(_tokenA), IERC20(_tokenB), addedA, addedB);
    }

    function swapToSyncDexPrice(
        IUniswapV2Router _uniswapV2Router,
        IPriceReader _priceReader,
        IERC20Metadata _tokenA,
        IERC20Metadata _tokenB,
        string memory _symbolA,
        string memory _symbolB,
        uint256 _maxSwapA,
        uint256 _maxSwapB
    )
        public
        onlyOwner
    {
        (uint256 priceA, uint256 priceB) = InfoTool.conormalizedPrices(_priceReader, _symbolA, _symbolB);
        (uint256 swapA, uint256 swapB) = InfoTool.tokensToSwapForDexPriceSync(
            _uniswapV2Router, _tokenA, _tokenB, priceA, priceB, _maxSwapA, _maxSwapB);
        _swap(_uniswapV2Router, IERC20(_tokenA), IERC20(_tokenB), swapA, swapB);
    }

    function withdrawPool(
        IUniswapV2Router _uniswapV2Router,
        IERC20 _tokenA,
        IERC20 _tokenB,
        address _to
    )
        external
        onlyOwner
    {
        IERC20 pool = IERC20(_uniswapV2Router.pairFor(address(_tokenA), address(_tokenB)));
        uint256 liquidity = pool.balanceOf(address(this));
        _uniswapV2Router.removeLiquidity(
            address(_tokenA),
            address(_tokenB),
            liquidity,
            0, 0,
            address(this),
            block.timestamp
        );
        withdrawToken(_tokenA, _to);
        withdrawToken(_tokenB, _to);
    }

    function withdrawToken(
        IERC20 _token,
        address _to
    )
        public
        onlyOwner
    {
        uint256 amount = _token.balanceOf(address(this));
        _token.transfer(_to, amount);
    }

    function withdrawNative(
        address _to
    )
        external
        onlyOwner
    {
        uint256 amount = address(this).balance;
        (bool success,) = _to.call{value: amount}("");
        require(success, "DexPriceSyncer: withdrawNative failed");
    }

    function _addLiquidity(
        IUniswapV2Router _uniswapV2Router,
        IERC20 _tokenA, IERC20 _tokenB,
        uint256 _addedA, uint256 _addedB
    )
        private
    {
        if (_addedA > 0 && _addedB > 0) {
            _tokenA.approve(address(_uniswapV2Router), _addedA);
            _tokenB.approve(address(_uniswapV2Router), _addedB);
            _uniswapV2Router.addLiquidity(
                address(_tokenA),
                address(_tokenB),
                _addedA,
                _addedB,
                0, 0, 0, 0,
                address(this),
                block.timestamp
            );
            _tokenA.approve(address(_uniswapV2Router), 0);
            _tokenB.approve(address(_uniswapV2Router), 0);
        }
    }

    function _swap(
        IUniswapV2Router _uniswapV2Router,
        IERC20 _tokenA, IERC20 _tokenB,
        uint256 _swapA, uint256 _swapB
    )
        private
    {
        if (_swapA > 0) {
            _tokenA.approve(address(_uniswapV2Router), _swapA);
            _uniswapV2Router.swapExactTokensForTokens(
                _swapA, 0,
                _toDynamicArray(address(_tokenA), address(_tokenB)),
                address(this), block.timestamp
            );
            _tokenA.approve(address(_uniswapV2Router), 0);
        } else if (_swapB > 0) {
            _tokenB.approve(address(_uniswapV2Router), _swapB);
            _uniswapV2Router.swapExactTokensForTokens(
                _swapB, 0,
                _toDynamicArray(address(_tokenB), address(_tokenA)),
                address(this), block.timestamp
            );
            _tokenB.approve(address(_uniswapV2Router), 0);
        }
    }

    function _toDynamicArray(
        address _x,
        address _y
    )
        private pure
        returns (address[] memory)
    {
        address[] memory arr = new address[](2);
        arr[0] = _x;
        arr[1] = _y;
        return arr;
    }

    function _capWithBalance(
        IERC20 _token,
        address _owner,
        uint256 _amount
    )
        private view
        returns (uint256)
    {
        uint256 _balance = _token.balanceOf(_owner);
        return _min(_balance, _amount);
    }

    function _min(
        uint256 _x,
        uint256 _y
    )
        private pure
        returns (uint256)
    {
        return _x > _y ? _y : _x;
    }

}