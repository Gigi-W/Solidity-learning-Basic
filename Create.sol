// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;
contract Pair{
    address public factory;
    address public token0;
    address public token1;
    constructor() payable{
        factory = msg.sender;
    }
    function init(address _token0,address _token1) external{
        require(factory==msg.sender, 'uniswap:FORBIDDEN');
        token0=_token0;
        token1=_token1;
    }
}

contract PairFactory{
    mapping(address=>mapping(address=>address)) public getPair;
    address[] public allPairs;

    // 可以通过两个代币找到这个币对资金池
    function createPair(address tokenA,address tokenB) external returns(address pairAddress){
        Pair pair = new Pair();
        pair.init(tokenA,tokenB);
        pairAddress = address(pair);
        allPairs.push(pairAddress);
        getPair[tokenA][tokenB] = pairAddress;
        getPair[tokenB][tokenA] = pairAddress;
    }
}