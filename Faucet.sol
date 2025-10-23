// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import './ERC20.sol';

contract Faucet{
    // 发放代币事件
    event SendToken(address indexed receiver, uint256 indexed value);

    address public contractMyERC20; // 代币合约地址
    uint256 public amountAllowed = 50; // 领取数量
    mapping(address=>bool) public requestedAddress;  // 领取记录

    constructor(address contractMyERC20_){
        contractMyERC20 = contractMyERC20_;  // 确定发放ERC20的代币地址
    }

    function requestToken() external{
        require(!requestedAddress[msg.sender], "Can't request multiple times");
        IERC20 token = IERC20(contractMyERC20);
        require(token.balanceOf(address(this))>=amountAllowed, "Faucet is Empty!");
        token.transfer(msg.sender, amountAllowed);
        requestedAddress[msg.sender]=true; // 记录领取地址
        emit SendToken(msg.sender,amountAllowed);
    }
}