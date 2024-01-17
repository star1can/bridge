// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import './BridgeToken.sol';
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";


abstract contract BridgeBase is Ownable, ReentrancyGuard {
    
    struct Message {
        address owner;
        uint256 amount;
        uint256 nonce;
    }

    enum Step { Burn, Mint, Lock, Unlock }

    event Transfer(
        address owner,
        uint amount,
        uint nonce,
        bytes
         signature,
        Step indexed step
    );
    BridgeToken public token;

    mapping(address => mapping(uint => bool)) public processedNonces;

    mapping(address => uint) private locked;
    mapping(address => uint) private minted;

    constructor(address _token, address _admin) Ownable(_admin) {   
        token = BridgeToken(_token);   
    }

    function lock(address _owner, uint256 _nonce, bytes calldata _signature) external nonReentrant payable {
        prepare(_owner, _nonce, msg.value, _signature);

        uint256 fee = Math.mulDiv(msg.value, 8, 1000);
        locked[_owner] += msg.value - fee;

        emit Transfer(
            _owner,
            msg.value,
            _nonce,
            _signature,
            Step.Lock
        );
    }

    function mint(address _owner, uint256 _nonce, uint256 _amount, bytes calldata _signature) external nonReentrant onlyOwner {
        prepare(_owner, _nonce, _amount, _signature);

        uint256 fee = Math.mulDiv(_amount, 8, 1000);
        _amount -= fee;

        minted[_owner] += _amount;
        token.mint(_owner, _amount);

        emit Transfer(
            _owner,
            _amount,
            _nonce,
            _signature,
            Step.Mint
        );
    }

    function burn(address _owner, uint256 _nonce, uint256 _amount, bytes calldata _signature) external nonReentrant {
        prepare(_owner, _nonce, _amount, _signature);

        require(minted[_owner] >= _amount, "Not enough tokens to burn!");

        minted[_owner] -= _amount;
        token.burn(_owner, _amount);

        emit Transfer(
            _owner,
            _amount,
            _nonce,
            _signature,
            Step.Burn
        );
    }

    function unlock(address _owner, uint256 _nonce, uint256 _amount, bytes calldata _signature) external nonReentrant onlyOwner payable {
        prepare(_owner, _nonce, _amount, _signature);

        require(locked[_owner] >= _amount, "Not enough tokens to unlock!");

        locked[_owner] -= _amount;
        payable(_owner).transfer(_amount);

        emit Transfer(
            _owner,
            _amount,
            _nonce,
            _signature,
            Step.Unlock
        );
    }

    function prepare(address _owner, uint256 _nonce, uint256 _amount, bytes calldata _signature) private {
        require(processedNonces[_owner][_nonce] == false, "Request with this nonce already processed!");
        processedNonces[_owner][_nonce] = true;

        require(_amount > 0, "Can't exchange zero!");

        Message memory message = Message(_owner, _amount, _nonce);
        require(recoverSigner(message, _signature) == _owner, "Sign verify failed!");
    }
    
    function recoverSigner(Message memory _message, bytes memory _signature) private pure returns (address){
        bytes32 digest = getHash(_message);
        return ECDSA.recover(digest, _signature);
    }

    function getHash(Message memory _message) private pure returns (bytes32){
        return MessageHashUtils.toEthSignedMessageHash(keccak256(abi.encodePacked(_message.owner,_message.amount,_message.nonce)));             
    }

}