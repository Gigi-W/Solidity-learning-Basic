// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;
contract Receive{
    event fallbackEvent(address sender, uint256 value, bytes data);
    fallback() external payable{
        emit fallbackEvent(msg.sender,msg.value,msg.data);
    }
}