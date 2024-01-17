// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


abstract contract BridgeToken is ERC20, Ownable {
    constructor(address _owner, string memory _name, string memory _symbol)
        ERC20(_name, _symbol)
        Ownable(_owner)
    {}

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) public onlyOwner {
        _burn(from, amount);
    }

    function decimals() public pure override returns (uint8) {
        return 18;
    }
}