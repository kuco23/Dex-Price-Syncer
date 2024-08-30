// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


contract ERC20Mock is ERC20 {
    uint8 private __decimals;

    constructor(string memory _name, string memory _symbol, uint8 _decimals) ERC20(_name, _symbol) {
        __decimals = _decimals;
    }

    function decimals() public view override returns (uint8) {
        return __decimals;
    }

    function mint(address _target, uint256 amount) public {
        _mint(_target, amount);
    }

    function burn(address _target, uint256 _amount) public {
        _burn(_target, _amount);
    }

    function deposit() public payable {
        _mint(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) external {
        _burn(msg.sender, amount);
        payable(msg.sender).transfer(amount);
    }
}
