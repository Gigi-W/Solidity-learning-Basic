// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;
contract Events{
    mapping(address => uint256) public _balances;
    event Transfer(address indexed from,address indexed to,uint256 amount);
    function _transfer(address from,address to, uint256 amount) public{
        _balances[from]=100000;
        _balances[from]-=amount;
        _balances[to]+=amount;
        emit Transfer(from,to,amount);
    }
}