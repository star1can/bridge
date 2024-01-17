// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import './BridgeBase.sol';

contract EthBridge is BridgeBase {
    constructor(address _token)
        BridgeBase(_token, msg.sender) 
    {}
}