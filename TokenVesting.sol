// SPDX-License-Identifier:MIT
pragma solidity ^0.8.21;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.9.3/contracts/token/ERC20/IERC20.sol";

contract TokenVesting{
    address public immutable beneficiary; // 受益人地址
    uint256 public immutable start; // 开始时间戳，秒
    uint256 public immutable duration; // 归属期，秒
    mapping (address=> uint256) public erc20Released; // 已释放代币=>数量映射

    constructor(address _beneficiary, uint256 _duration){
        require(_beneficiary!=address(0), 'beneficiary address is the 0 address');
        beneficiary = _beneficiary;
        start = block.timestamp;
        duration = _duration;
    }

    function release(address token, uint amount) external {
        // 当前时间释放的代币总量 - 已经领取的
        uint releaseable = vestingAmount(token, block.timestamp) - erc20Released[token];
        require(amount<=releaseable, 'exceeding');
        erc20Released[token] += amount;
        IERC20(token).transfer(beneficiary, amount);
    }

    function vestingAmount(address token, uint256 timestamp) private view returns(uint256){
        // 未被领取+已领取
        uint total = IERC20(token).balanceOf(address(this)) + erc20Released[token];
        if(timestamp < start){
            return 0;
        }else if(timestamp > start + duration){
            return total;
        }else{
            return total * (timestamp - start) / duration;
        }
    }
}