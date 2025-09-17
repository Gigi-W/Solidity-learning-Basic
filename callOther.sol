// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;
contract OtherContract{
    event ReceiveLog(uint256 amount,uint256 gas);

    uint256 private _x = 0;
    // 返回合约余额
    function getBalance() external view returns(uint256){
        return address(this).balance;
    }

    // 设置x并支持转入ETH
    function setX(uint256 x) external payable{
        _x = x;
        if(msg.value>0){
            emit ReceiveLog(msg.value,gasleft());
        }
    }

    // 获取x
    function getX() external view returns(uint256){
        return _x;
    }
}

contract CallContract{
    // 传入合约地址
    function setCallX(address _address,uint256 x) external {
        OtherContract(_address).setX(x);
    }

    // 传入合约类型
    function getCallX(OtherContract _address) external view returns(uint256){
        return _address.getX();
    }

    // 创建合约变量
    function createVar(address _address) external view returns(uint256){
        OtherContract oc = OtherContract(_address);
        return oc.getX();
    }


    // 转账
    function sendAndsetX(address _address,uint256 amount, uint256 x) external payable{
        OtherContract(_address).setX{value: amount}(x);
    }
}