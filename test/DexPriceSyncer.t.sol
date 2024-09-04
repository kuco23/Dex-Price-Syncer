// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {IUniswapV2Router} from "../src/interface/IUniswapV2Router.sol";
import {IPriceReader} from "../src/interface/IPriceReader.sol";
import {UniswapV2RouterMock} from "../src/mock/UniswapV2/UniswapV2RouterMock.sol";
import {PriceReaderMock} from "../src/mock/PriceReaderMock.sol";
import {ERC20Mock} from "../src/mock/ERC20Mock.sol";
import {Math} from "../src/lib/Math.sol";
import {PriceCalc} from "../src/lib/PriceCalc.sol";
import {DexPriceSyncer} from "../src/DexPriceSyncer.sol";


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

uint256 constant MAX_PRICE_DECIMAL_DIFF = 3; // can be set to 5 for add liquidity,
// for swap it's hard to eliminate the problematic values
uint256 constant MAX_PRICE_ERROR = PriceCalc.PRICE_PRECISION / 10 ** MAX_PRICE_DECIMAL_DIFF;

contract DexPriceSyncerTest is Test {
    DexPriceSyncer public dexPriceSyncer;
    IUniswapV2Router public uniswapV2Router;

    function setUp() public {
        uniswapV2Router = new UniswapV2RouterMock(address(0));
        dexPriceSyncer = new DexPriceSyncer();
    }

    function test_AddLiquidityToSyncDexPrice(
        uint16 decimals,
        uint64 priceA,
        uint64 priceB
    ) external {
        (uint8 decimalsA, uint8 decimalsB, uint8 priceDecimalsA, uint8 priceDecimalsB) = extrapolateDecimals(decimals);
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
        (uint256 reserveA, uint256 reserveB) = uniswapV2Router.getReserves(address(tokenA), address(tokenB));
        assertTrue(reserveA == initialSupplyA || reserveB == initialSupplyB);
        // check dex price vs price reader price
        uint256 relativePriceDiff = dexPriceSyncer.dexRelativeTokenPriceDiff(
            uniswapV2Router, priceReader, tokenA, tokenB, "TKA_symbol", "TKB_symbol"
        );
        assertLe(relativePriceDiff, MAX_PRICE_ERROR);
    }

    function test_SwapToSyncDexPrice(
        uint16 decimals,
        uint64 priceA,
        uint64 priceB,
        uint32 _initialLiquidityA,
        uint32 _initialLiquidityB
    ) external {
        (uint8 decimalsA, uint8 decimalsB, uint8 priceDecimalsA, uint8 priceDecimalsB) = extrapolateDecimals(decimals);
        restrictParams(decimalsA, decimalsB, priceDecimalsA, priceDecimalsB, priceA, priceB);
        uint256 initialLiquidityA = uint256(_initialLiquidityA) + uint32(10 ** decimalsA);
        uint256 initialLiquidityB = uint256(_initialLiquidityB) + uint32(10 ** decimalsB);
        uint256 initialSupplyA = type(uint112).max;
        uint256 initialSupplyB = type(uint112).max;
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

    function extrapolateDecimals(
        uint16 decimals
    )
        internal pure
        returns (uint8, uint8, uint8, uint8)
    {
        uint8 decimalsA = 4 + uint8(decimals & 0xf);
        uint8 decimalsB = 4 + uint8((decimals >> 4) & 0xf);
        uint8 priceDecimalsA = 4 + uint8((decimals >> 8) & 0xf);
        uint8 priceDecimalsB = 4 + uint8((decimals >> 12) & 0xf);
        return (decimalsA, decimalsB, priceDecimalsA, priceDecimalsB);
    }

    function restrictParams(
        uint8 decimalsA,
        uint8 decimalsB,
        uint8 priceDecimalsA,
        uint8 priceDecimalsB,
        uint64 priceA,
        uint64 priceB
    )
        internal pure
    {
        vm.assume(decimalsA >= 2  && decimalsA <= 20);
        vm.assume(decimalsB >= 2 && decimalsB <= 20);
        vm.assume(priceDecimalsA >= 2 && priceDecimalsA <= 10);
        vm.assume(priceDecimalsB >= 2 && priceDecimalsB <= 10);
        vm.assume(priceA > 0 && priceB > 0 && priceA > 10_000 && priceB > 10_000);
        uint256 _unitPriceAB = PriceCalc.relativeUnitPrice(priceA, priceB, decimalsA, decimalsB);
        vm.assume(_unitPriceAB > 0 && _unitPriceAB <= type(uint64).max);
        uint256 _unitPriceBA = PriceCalc.relativeUnitPrice(priceB, priceA, decimalsB, decimalsA);
        vm.assume(_unitPriceBA > 0 && _unitPriceBA <= type(uint64).max);
        uint256 _tokenPriceAB = PriceCalc.relativePrice(priceA, priceB);
        vm.assume(_tokenPriceAB > 0 && _tokenPriceAB <= type(uint64).max);
        uint256 _tokenPriceBA = PriceCalc.relativePrice(priceB, priceA);
        vm.assume(_tokenPriceBA > 0 && _tokenPriceBA <= type(uint64).max);
    }
}
