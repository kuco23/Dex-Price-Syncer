// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {ERC20Mock} from "../src/mock/ERC20Mock.sol";
import {PriceReaderMock} from "../src/mock/PriceReaderMock.sol";
import {UniswapV2RouterMock} from "../src/mock/UniswapV2/UniswapV2RouterMock.sol";
import {IUniswapV2Router} from "../src/interface/IUniswapV2Router.sol";
import {IPriceReader} from "../src/interface/IPriceReader.sol";
import {DexPriceSyncer} from "../src/DexPriceSyncer.sol";
import {PriceCalc} from "../src/lib/PriceCalc.sol";


uint256 constant MAX_PRICE_BIPS = 1e5;
uint256 constant ALLOWED_PRICE_DIFF_BIPS = 1;


contract DexPriceSyncerTest is Test {
    DexPriceSyncer public dexPriceSyncer;
    IUniswapV2Router public uniswapV2Router;

    function setUp() public {
        uniswapV2Router = new UniswapV2RouterMock(address(0));
        dexPriceSyncer = new DexPriceSyncer();
    }

    function test_AddLiquidityToSyncDexPrice(
        uint8 decimalsA,
        uint8 decimalsB,
        uint8 priceDecimalsA,
        uint8 priceDecimalsB,
        uint80 priceA,
        uint80 priceB
    ) public {
        vm.assume(decimalsA > 0 && decimalsA <= 20);
        vm.assume(decimalsB > 0 && decimalsB <= 20);
        vm.assume(priceDecimalsA > 0 && priceDecimalsA <= 10);
        vm.assume(priceDecimalsB > 0 && priceDecimalsB <= 10);
        vm.assume(priceA > 0 && priceB > 0);
        vm.assume(PriceCalc.relativeUnitPrice(priceA, priceB, decimalsA, decimalsB) > 0);
        vm.assume(PriceCalc.relativeUnitPrice(priceB, priceA, decimalsB, decimalsA) > 0);
        vm.assume(PriceCalc.relativePrice(priceA, priceB) > 0);
        vm.assume(PriceCalc.relativePrice(priceB, priceA) > 0);
        /* // params
        uint8 decimalsA = 17;
        uint8 decimalsB = 6;
        uint8 priceDecimalsA = 5;
        uint8 priceDecimalsB = 3;
        uint256 priceA = 1e7;
        uint256 priceB = 1e5; */
        // calc
        uint256 initialSupplyA = type(uint96).max;
        uint256 initialSupplyB = type(uint96).max;
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
            uniswapV2Router,
            priceReader,
            tokenA,
            tokenB,
            "TKA_symbol",
            "TKB_symbol",
            initialSupplyA,
            initialSupplyB
        );
        // check
        (uint256 reserveA, uint256 reserveB) = uniswapV2Router.getReserves(address(tokenA), address(tokenB));
        uint256 dexPrice = PriceCalc.relativeTokenDexPrice(reserveA, reserveB, decimalsA, decimalsB);
        (uint256 normalPriceA, uint256 normalPriceB) = PriceCalc.conormalizePrices(
            priceA, priceB, priceDecimalsA, priceDecimalsB);
        uint256 expectedPrice = PriceCalc.relativePrice(normalPriceA, normalPriceB);
        console.log("dexPrice: %d, expectedPrice: %d", dexPrice, expectedPrice);
        assertLe(relDiffBips(dexPrice, expectedPrice), ALLOWED_PRICE_DIFF_BIPS);
    }

    function relDiffBips(uint256 x, uint256 y) private pure returns (uint256) {
        uint256 _max = max(x, y);
        return _max == 0 ? 0 : MAX_PRICE_BIPS * diff(x, y) / _max;
    }

    function diff(uint256 x, uint256 y) private pure returns (uint256) {
        return x > y ? x - y : y - x;
    }

    function max(uint256 x, uint256 y) private pure returns (uint256) {
        return x > y ? x : y;
    }
}
