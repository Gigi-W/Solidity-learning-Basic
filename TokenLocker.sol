// SPDX-License-Identifier:MIT
pragma solidity ^0.8.21;

// 代币锁合约，防止LP项目方突然撤出，发生rug-pull
contract TokenLocker{
    address public immutable beneficiary; // 受益人
    uint public immutable startTime; // 锁仓起始时间
    uint public immutable duration; // 锁仓期
    address public immutable token; // 要锁的代币地址

    constructor(address _token, address _benefitiary, uint _duration){
        require(duration>0,"must greater than 0");
        require(_benefitiary!=address(0), '0 address');
        beneficiary = _benefitiary;
        startTime = block.timestamp;
        duration = _duration;
        token = _token;
    }

    function release() external{
        require((block.timestamp - start)>=duration, "early withdrawal");
        uint amount = IERC20(token).balanceOf(address(this));
        require(amount>0, "amount must be greater than 0")
        IERC20(token).transfer(beneficiary, lockAmount);
    }
}