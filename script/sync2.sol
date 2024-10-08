// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {IERC20Metadata, IERC20} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {DexPriceSyncer} from "../src/DexPriceSyncer.sol";
import {IUniswapV2Router} from "../src/interface/IUniswapV2Router.sol";
import {IPriceReader} from "../src/interface/IPriceReader.sol";
import {InfoTool} from "../src/lib/InfoTool.sol";


contract Sync2 is Script {
    function setUp() public {}

    function run() public {
        address dexPriceSyncerAddress = vm.envAddress("DEX_PRICE_SYNCER_ADDRESS");
        DexPriceSyncer dexPriceSyncer = DexPriceSyncer(dexPriceSyncerAddress);
        // periphery
        IUniswapV2Router uniswapV2Router = IUniswapV2Router(0xf0D01450C037DB2903CF5Ff638Dd1e2e6B0EEDF4);
        IPriceReader priceReader = IPriceReader(0xeBF92a31DAEF96Fe68E3d747d7233aE63B2Cf98C);
        // token A config
        IERC20Metadata tokenA = IERC20Metadata(0xe01b2151b684b83C771449D8A6D1d1764f03829e);
        string memory symbolA = "testBTC";
        uint256 maxSpentA = 10000000;
        // tokenB config
        IERC20Metadata tokenB = IERC20Metadata(0x767b25A658E8FC8ab6eBbd52043495dB61b4ea91);
        string memory symbolB = "CFLR";
        uint256 maxSpentB = 10000000000000000000000000;
        // prices
        (uint256 priceA,,) = priceReader.getPrice(symbolA);
        (uint256 priceB,,) = priceReader.getPrice(symbolB);
        console.log("price testBTC ", priceA);
        console.log("price CFLR    ", priceB);
        // balances
        console.log("balance testBTC ", tokenA.balanceOf(address(dexPriceSyncer)));
        console.log("balance CFLR    ", tokenB.balanceOf(address(dexPriceSyncer)));
        // reserves
        (uint256 _reserveA, uint256 _reserveB) = InfoTool.safelyGetDexReserves(
            uniswapV2Router, address(tokenA), address(tokenB)
        );
        console.log("reserve testBTC ", _reserveA);
        console.log("reserve CFLR    ", _reserveB);

        console.log(dexPriceSyncer.dexRelativeTokenPriceDiff(
            uniswapV2Router, priceReader, tokenA, tokenB, symbolA, symbolB
        ));
        // run
        //vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        vm.startPrank(dexPriceSyncer.owner());
        dexPriceSyncer.sync(
            uniswapV2Router, priceReader, tokenA, tokenB,
            symbolA, symbolB, maxSpentA, maxSpentB
        );
        (uint256 reserveA, uint256 reserveB) = InfoTool.safelyGetDexReserves(
            uniswapV2Router, address(tokenA), address(tokenB)
        );
        console.log("reserve testBTC ", reserveA);
        console.log("reserve CFLR    ", reserveB);
    }
}