// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "../interface/IPriceReader.sol";


contract PriceReaderMock is IPriceReader {
    using SafeCast for *;

    struct PricingData {
        uint8 decimals;
        uint128 price;
        uint64 timestamp;
        uint128 trustedPrice;
        uint64 trustedTimestamp;
    }

    address public provider;

    mapping(string symbol => PricingData) private pricingData;

    modifier onlyDataProvider {
        require(msg.sender == provider, "only provider");
        _;
    }

    constructor(address _provider)
    {
        provider = _provider;
    }

    function setDecimals(string memory _symbol, uint256 _decimals)
        external
        onlyDataProvider
    {
        pricingData[_symbol].decimals = _decimals.toUint8();
    }

    function setPrice(string memory _symbol, uint256 _price)
        external
        onlyDataProvider
    {
        PricingData storage data = _getPricingData(_symbol);
        data.price = _price.toUint128();
        data.timestamp = block.timestamp.toUint64();
    }

    function getPrice(string memory _symbol)
        external view
        returns (uint256 _price, uint256 _timestamp, uint256 _priceDecimals)
    {
        PricingData storage data = _getPricingData(_symbol);
        return (data.price, data.timestamp, data.decimals);
    }

    function _getPricingData(string memory _symbol)
        private view
        returns (PricingData storage)
    {
        PricingData storage data = pricingData[_symbol];
        require(data.decimals > 0, "price not initialized");
        return data;
    }
}
