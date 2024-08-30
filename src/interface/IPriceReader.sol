// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;


interface IPriceReader {
    function getPrice(string memory _symbol)
        external view
        returns (uint256 _price, uint256 _timestamp, uint256 _priceDecimals);
}
