// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

// 继承合约，重写函数
contract A{
    event Print(string a);

    function yeye() public virtual{
        emit Print('Gigi-a');
    }
}
// 继承构造函数
contract B{
    address public b;
    constructor(address _b){
        b = _b;
    }
}

// 继承修饰器
contract C{
    modifier verifyEqual0(uint c) virtual{
        require(c==0);
        _;
    }
}
// 调用父合约的函数
contract D{
    string[] public arr = ['a','b','c'];
    function pop() public{
        arr.pop();
    }
}
contract E is A,B(msg.sender),C,D{
    function yeye() public  override{
        emit Print('Gigi-e');
    }

    function add(uint x,uint y) public verifyEqual0(x) pure returns(uint){
        return x+y;
    }
    function callDPop() public{
        super.pop();
    }
}