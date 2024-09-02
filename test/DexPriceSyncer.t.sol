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


/* simple test example
    uint8 decimalsA = 17;
    uint8 decimalsB = 6;
    uint8 priceDecimalsA = 5;
    uint8 priceDecimalsB = 3;
    uint256 priceA = 1e7;
    uint256 priceB = 1e5;
    uint256 initialLiquidityA = 100_000 * 10 ** decimalsA;
    uint256 initialLiquidityB = 100_000 * 10 ** decimalsB;
 */


uint256 constant MAX_PRICE_ERROR_HR = 1e5;
uint256 constant MAX_PRICE_ERROR = PriceCalc.PRICE_PRECISION / MAX_PRICE_ERROR_HR;

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
    ) external {
        restrictParams(decimalsA, decimalsB, priceDecimalsA, priceDecimalsB, priceA, priceB);
        uint256 initialSupplyA = type(uint96).max;
        uint256 initialSupplyB = type(uint96).max;
        // test
        ERC20Mock tokenA = new ERC20Mock("TokenA", "TKA", decimalsA);
        ERC20Mock tokenB = new ERC20Mock("TokenB", "TKB", decimalsB);
        PriceReaderMock priceReader = new PriceReaderMock(address(this));
        priceReader.setDecimals("TKA_symbol", priceDecimalsA);
        priceReader.setDecimals("TKB_symbol", priceDecimalsB);
        priceReader.setPrice("TKA_symbol", priceA);
        priceReader.setPrice("TKB_symbol", priceB);
        tokenA.mint(address(dexPriceSyncer), initialSupplyA);
        tokenB.mint(address(dexPriceSyncer), initialSupplyB);
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
        // check dex price vs price reader price
        uint256 relativePriceDiff = dexPriceSyncer.dexRelativeTokenPriceDiff(
            uniswapV2Router, priceReader, tokenA, tokenB, "TKA_symbol", "TKB_symbol"
        );
        assertLe(relativePriceDiff, MAX_PRICE_ERROR);
    }

    function test_SwapToSyncDexPrice(
        uint8 decimalsA,
        uint8 decimalsB,
        uint8 priceDecimalsA,
        uint8 priceDecimalsB,
        uint80 priceA,
        uint80 priceB,
        uint96 initialLiquidityA,
        uint96 initialLiquidityB
    ) external {
        restrictParams(decimalsA, decimalsB, priceDecimalsA, priceDecimalsB, priceA, priceB);
        vm.assume(initialLiquidityA >= 10 ** decimalsA);
        vm.assume(initialLiquidityB >= 10 ** decimalsB);
        uint256 initialSupplyA = type(uint96).max;
        uint256 initialSupplyB = type(uint96).max;
        // test
        ERC20Mock tokenA = new ERC20Mock("TokenA", "TKA", decimalsA);
        ERC20Mock tokenB = new ERC20Mock("TokenB", "TKB", decimalsB);
        PriceReaderMock priceReader = new PriceReaderMock(address(this));
        priceReader.setDecimals("TKA_symbol", priceDecimalsA);
        priceReader.setDecimals("TKB_symbol", priceDecimalsB);
        priceReader.setPrice("TKA_symbol", priceA);
        priceReader.setPrice("TKB_symbol", priceB);
        tokenA.mint(address(this), initialLiquidityA);
        tokenB.mint(address(this), initialLiquidityB);
        tokenA.approve(address(uniswapV2Router), initialLiquidityA);
        tokenB.approve(address(uniswapV2Router), initialLiquidityB);
        // add initial liquidity
        uniswapV2Router.addLiquidity(
            address(tokenA), address(tokenB),
            initialLiquidityA, initialLiquidityB,
            0, 0, 0, 0,
            address(this),
            block.timestamp
        );
        tokenA.mint(address(dexPriceSyncer), initialSupplyA);
        tokenB.mint(address(dexPriceSyncer), initialSupplyB);
        dexPriceSyncer.swapToSyncDexPrice(
            uniswapV2Router,
            priceReader,
            tokenA,
            tokenB,
            "TKA_symbol",
            "TKB_symbol",
            initialSupplyA,
            initialSupplyB
        );
        // check dex price vs price reader price
        uint256 relativePriceDiff = dexPriceSyncer.dexRelativeTokenPriceDiff(
            uniswapV2Router, priceReader, tokenA, tokenB, "TKA_symbol", "TKB_symbol"
        );
        assertLe(relativePriceDiff, MAX_PRICE_ERROR);
    }

    function restrictParams(
        uint8 decimalsA,
        uint8 decimalsB,
        uint8 priceDecimalsA,
        uint8 priceDecimalsB,
        uint80 priceA,
        uint80 priceB
    ) internal pure {
        vm.assume(decimalsA > 2 && decimalsA <= 20);
        vm.assume(decimalsB > 2 && decimalsB <= 20);
        vm.assume(priceDecimalsA > 2 && priceDecimalsA <= 10);
        vm.assume(priceDecimalsB > 2 && priceDecimalsB <= 10);
        vm.assume(priceA > 0 && priceB > 0);
        uint256 _unitPriceAB = PriceCalc.relativeUnitPrice(priceA, priceB, decimalsA, decimalsB);
        vm.assume(_unitPriceAB > 0 && _unitPriceAB <= type(uint80).max);
        uint256 _unitPriceBA = PriceCalc.relativeUnitPrice(priceB, priceA, decimalsB, decimalsA);
        vm.assume(_unitPriceBA > 0 && _unitPriceBA <= type(uint80).max);
        uint256 _tokenPriceAB = PriceCalc.relativePrice(priceA, priceB);
        vm.assume(_tokenPriceAB > 0 && _tokenPriceAB <= type(uint80).max);
        uint256 _tokenPriceBA = PriceCalc.relativePrice(priceB, priceA);
        vm.assume(_tokenPriceBA > 0 && _tokenPriceBA <= type(uint80).max);
    }
}
