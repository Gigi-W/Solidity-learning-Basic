// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;
contract Pair{
    address public factory;
    address public token0;
    address public token1;
    constructor(){
        factory = msg.sender;
    }
    function init(address _token0, address _token1) external{
        require(factory==msg.sender,"FORBIDDEN");
        token0 = _token0;
        token1 = _token1;
    }
}

// 创建合约
contract PairFactory2{
    mapping(address=>mapping(address=>address)) public getPair;
    address[] public pairArr;
    function createPair(address tokenA, address tokenB) external returns(address pairAdd){
        require(tokenA!=tokenB);
        bytes32 _salt = tokenA>tokenB? keccak256(abi.encodePacked(tokenB,tokenA)):keccak256(abi.encodePacked(tokenA,tokenB));
        // (address token0,address token1) = tokenA > tokenB ? (tokenB,tokenA):(tokenA,tokenB);
        // bytes 32 _salt = keccak256(abi.encodePacked(token0,token1);
        Pair pair = new Pair{salt: _salt}();
        pair.init(tokenA,tokenB);
        pairAdd = address(pair);
        pairArr.push(pairAdd);
        getPair[tokenA][tokenB] = pairAdd;
        getPair[tokenB][tokenA] = pairAdd;
    }

    // 手动计算
    function caculcatePairAddress(address tokenA,address tokenB) external view returns(address pairAdd){
        // 0xff 新合约的创建者地址 salt值 新合约代码
        bytes1 num = bytes1(0xff);
        address createAddress = address(this);
        (address token0,address token1)=tokenA > tokenB ? (tokenB,tokenA):(tokenA,tokenB);
        bytes32 _salt = keccak256(abi.encodePacked(token0,token1));
        bytes32 _createCode = keccak256(type(Pair).creationCode);
        pairAdd = address(uint160(uint256(keccak256(abi.encodePacked(num,createAddress,_salt,_createCode)))));
    }
}