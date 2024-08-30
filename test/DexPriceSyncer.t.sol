// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/console.sol";
import {Test, console} from "forge-std/Test.sol";
import {ERC20Mock} from "../src/mock/ERC20Mock.sol";
import {PriceReaderMock} from "../src/mock/PriceReaderMock.sol";
import {UniswapV2RouterMock} from "../src/mock/UniswapV2/UniswapV2RouterMock.sol";
import {IUniswapV2Router} from "../src/interface/IUniswapV2Router.sol";
import {IPriceReader} from "../src/interface/IPriceReader.sol";
import {DexPriceSyncer} from "../src/DexPriceSyncer.sol";
import {PriceCalc} from "../src/lib/PriceCalc.sol";


contract DexPriceSyncerTest is Test {
    DexPriceSyncer public dexPriceSyncer;
    IUniswapV2Router public uniswapV2Router;

    function setUp() public {
        uniswapV2Router = new UniswapV2RouterMock(address(0));
        dexPriceSyncer = new DexPriceSyncer();
    }

    function test_AddLiquidityToSyncDexPrice() public {
        ERC20Mock tokenA = new ERC20Mock("TokenA", "TKA", 18);
        ERC20Mock tokenB = new ERC20Mock("TokenB", "TKB", 6);
        tokenA.mint(address(dexPriceSyncer), 1e25);
        tokenB.mint(address(dexPriceSyncer), 1e15);
        PriceReaderMock priceReader = PriceReaderMock(address(this));
        priceReader.setDecimals("TKA", 5);
        priceReader.setDecimals("TKB", 3);
        priceReader.setPrice("TKA", 1e7);
        priceReader.setPrice("TKB", 1e5);
        dexPriceSyncer.addLiquidityToSyncDexPrice(
            uniswapV2Router, tokenA, tokenB, priceReader, priceReader, "TKA", "TKB", 1e17, 1e10);
        // check
        (uint256 reserveA, uint256 reserveB) = uniswapV2Router.getReserves(address(tokenA), address(tokenB));
        uint256 _price = PriceCalc.relativeTokenDexPrice(reserveA, reserveB, 18, 6);
        console.log("reserveA: %d, reserveB: %d, price: %d", reserveA, reserveB, _price);
    }
}
