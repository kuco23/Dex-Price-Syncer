// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;


library Math {

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function relDiff(uint256 x, uint256 y, uint256 precision) internal pure returns (uint256) {
        uint256 _max = max(x, y);
        return _max == 0 ? 0 : precision * diff(x, y) / _max;
    }

    function diff(uint256 x, uint256 y) internal pure returns (uint256) {
        return x > y ? x - y : y - x;
    }
}