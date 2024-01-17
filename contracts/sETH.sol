// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import './BridgeToken.sol';

contract sETH is BridgeToken {
    constructor(address _owner)
        BridgeToken(_owner, "sETH", "SETH")
    {
    }
}