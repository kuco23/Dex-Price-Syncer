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
        // params
        uint8 decimalsA = 17;
        uint8 decimalsB = 6;
        uint8 priceDecimalsA = 5;
        uint8 priceDecimalsB = 3;
        uint256 priceA = 1e7;
        uint256 priceB = 1e5;
        // calc
        uint256 initialSupplyA = 100_000 * 10 ** decimalsA;
        uint256 initialSupplyB = 100_000 * 10 ** decimalsB;
        // test
        ERC20Mock tokenA = new ERC20Mock("TokenA", "TKA", decimalsA);
        ERC20Mock tokenB = new ERC20Mock("TokenB", "TKB", decimalsB);
        tokenA.mint(address(dexPriceSyncer), initialSupplyA);
        tokenB.mint(address(dexPriceSyncer), initialSupplyB);
        PriceReaderMock priceReader = new PriceReaderMock(address(this));
        priceReader.setDecimals("TKA_symbol", priceDecimalsA);
        priceReader.setDecimals("TKB_symbol", priceDecimalsB);
        priceReader.setPrice("TKA_symbol", priceA);
        priceReader.setPrice("TKB_symbol", priceB);
        dexPriceSyncer.addLiquidityToSyncDexPrice(
            uniswapV2Router, priceReader,
            tokenA, tokenB,
            "TKA_symbol", "TKB_symbol",
            initialSupplyA, initialSupplyB
        );
        // check
        (uint256 reserveA, uint256 reserveB) = uniswapV2Router.getReserves(address(tokenA), address(tokenB));
        uint256 _price = PriceCalc.relativeTokenDexPrice(reserveA, reserveB, decimalsA, decimalsB);
        (uint256 _normalPriceA, uint256 _normalPriceB) = PriceCalc.conormalizePrices(priceA, priceB, priceDecimalsA, priceDecimalsB);
        assertEq(_price, PriceCalc.relativePrice(_normalPriceA, _normalPriceB));
    }
}
