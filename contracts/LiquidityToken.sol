// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import './BridgeToken.sol';


contract LiquidityToken is BridgeToken {
    constructor()
        BridgeToken(msg.sender, "lt", "LT")
    {}
}