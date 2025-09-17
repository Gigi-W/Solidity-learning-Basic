// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

// 接收ETH合约，用于接收ETH和查询余额
contract ReceiveETH{
    event Log(address sender,uint256 value,uint256 gas);
    receive() external payable{
        emit Log(msg.sender, msg.value, gasleft());
    }
    function getBalance() external view returns(uint256){
        return address(this).balance; // 合约地址的余额，跟部署合约者、调用合约者不一样
    }
}

// 发送ETH合约
contract Transfer{
    event Log(address sender,uint256 value,uint256 gas);
    receive() external payable{
        emit Log(msg.sender,msg.value,gasleft());
    }

    // 使用transfer，gas限制2300
    function transferETH(address payable _to,uint256 _amount) external payable{
        _to.transfer(_amount);
    }

    // 使用send，gas限制2300，交易失败不触发revert，需要自定义实现
    error ErrorSend();
    function sendETH(address payable _to,uint256 _amount) external payable{
        bool _success = _to.send(_amount);
        if(!_success){
            revert ErrorSend();
        }
    }

    // 使用call，has无限制
    function callETH(address payable _to,uint256 amount) external payable{
        (bool success,) = _to.call{value: amount}("");
        if(!success){
            revert ErrorSend();
        }
    }
}