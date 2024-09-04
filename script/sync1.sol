// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {IERC20Metadata, IERC20} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {DexPriceSyncer} from "../src/DexPriceSyncer.sol";
import {IUniswapV2Router} from "../src/interface/IUniswapV2Router.sol";
import {IPriceReader} from "../src/interface/IPriceReader.sol";


contract Sync1 is Script {
    function setUp() public {}

    function run() public {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        DexPriceSyncer dexPriceSyncer = DexPriceSyncer(vm.envAddress("DEX_PRICE_SYNCER_ADDRESS"));
        // periphery
        IUniswapV2Router uniswapV2Router = IUniswapV2Router(0xf0D01450C037DB2903CF5Ff638Dd1e2e6B0EEDF4);
        IPriceReader priceReader = IPriceReader(0xeBF92a31DAEF96Fe68E3d747d7233aE63B2Cf98C);
        // token A config
        IERC20Metadata tokenA = IERC20Metadata(0x5905Df703221d4Ea311E85edEa860734b2072C7d);
        string memory symbolA = "testXRP";
        uint256 maxSpentA = 5000000000;
        // tokenB config
        IERC20Metadata tokenB = IERC20Metadata(0xd20D9284E8b43C60365BcA90662C67B5A0B91dd6);
        string memory symbolB = "testUSDC";
        uint256 maxSpentB = 1000000000;
        // check balance
        console.log("balanceA", tokenA.balanceOf(address(dexPriceSyncer)));
        console.log("balanceB", tokenB.balanceOf(address(dexPriceSyncer)));
        // run
        uint256 diff = dexPriceSyncer.dexRelativeTokenPriceDiff(
            uniswapV2Router, priceReader, tokenA, tokenB, symbolA, symbolB
        );
        console.log(diff);
        vm.broadcast(privateKey);
        dexPriceSyncer.sync(
            uniswapV2Router, priceReader, tokenA, tokenB,
            symbolA, symbolB, maxSpentA, maxSpentB
        );
        uint256 diff2 = dexPriceSyncer.dexRelativeTokenPriceDiff(
            uniswapV2Router, priceReader, tokenA, tokenB, symbolA, symbolB
        );
        console.log(diff2);
    }
}