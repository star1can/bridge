// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import './BridgeToken.sol';
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import './LiquidityToken.sol';


contract LiquidityPool is ReentrancyGuard {

    uint private FEE = 3;
    uint private DENOMINATOR = 1000;

    uint private reserve0;
    uint private reserve1;

    uint private totalSupply;

    BridgeToken private token1;
    LiquidityToken private liquidityToken;

    mapping(address => mapping(uint => uint)) providersToShares;
    mapping(address => uint) providerToLastSupply;

    constructor(address _bridgeToken, address _liquidityToken) {
        token1 = BridgeToken(_bridgeToken);
        liquidityToken = LiquidityToken(_liquidityToken);
    }

    function provideLiquidity(uint _amount1) external nonReentrant payable {
        require(_amount1 > 0 || msg.value > 0, "At least one share must be greater than 0");

        reserve0 += msg.value;
        reserve1 += _amount1;

        providersToShares[msg.sender][0] += msg.value;
        providersToShares[msg.sender][1] += _amount1;

        require(token1.transferFrom(msg.sender, address(this), _amount1), "Transfer failed");
        liquidityToken.mint(msg.sender, msg.value * _amount1);
    }

    function exchangeErcToCoin(uint _amount1) external nonReentrant {
        require(_amount1 > 0, "Can't exchange zero!");

        uint balance1 = token1.balanceOf(msg.sender);

        require(balance1 >= _amount1, "Not enough tokens!");

        uint k = reserve0 * reserve1;

        totalSupply += _amount1;
        reserve1 += _amount1;
        
        uint newCoinsCount = k / reserve1;
        uint sumToPay = reserve0 - newCoinsCount;

        uint fee = calculateFee(sumToPay);

        sumToPay -= fee;
        reserve0 = newCoinsCount;

        require(token1.transferFrom(msg.sender, address(this), _amount1), "Transfer failed!");
        payable(msg.sender).transfer(sumToPay);
    }

    function exchangeCoinToErc() external payable nonReentrant {
        require(msg.value > 0, "Can't exchange zero!");

        uint k = reserve0 * reserve1;

        totalSupply += msg.value;
        reserve0 += msg.value;
        
        uint newCoinsCount = k / reserve0;
        uint sumToPay = reserve0 - newCoinsCount;

        uint fee = calculateFee(sumToPay);

        sumToPay -= fee;
        reserve1 = newCoinsCount;

        token1.transfer(msg.sender, sumToPay);
    }

    function mint() external payable nonReentrant {

        uint share0 = providersToShares[msg.sender][0];
        uint share1 = providersToShares[msg.sender][1];

        require(share0 > 0 || share1 > 0 , "No shares found!");

        uint k = reserve0 * reserve1;
        uint kShare = share0 * share1;

        uint totalFees = calculateFee(totalSupply - providerToLastSupply[msg.sender]);

        if (kShare == 0) {
            return;
        }

        uint mintAmount = Math.mulDiv(totalFees, kShare, k);
        liquidityToken.mint(msg.sender, mintAmount);
    }

    function calculateFee(uint sum) private view returns(uint) {
        return Math.mulDiv(sum, FEE, DENOMINATOR);
    }
}