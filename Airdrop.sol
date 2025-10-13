// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;
import './MyERC20.sol';

contract Airdrop{
    // 空投数量总和
    function getSum(uint256[] calldata amounts) internal pure returns(uint256 sum){
        for(uint i = 0; i< amounts.length;i++){
            sum += amounts[i];
        }
    }

    // 发送ERC20代币空投：资金从调用者直接到接收者，合约只是 “代执行”（需授权），不经过合约余额（合约本身不会持有这些代币）。
    function sendERC20Token(address _token, address[] calldata _addresses, uint256[] calldata _amounts) external{
        require(_addresses.length == _amounts.length, "Length of Addresses and Amounts must be equal");
        uint256 sums = getSum(_amounts);
        IERC20 token = IERC20(_token);
        require(token.allowance(msg.sender, address(this))>=sums, "Need Approve ERC20 token");
        for(uint8 i;i<_addresses.length;i++){
            token.transferFrom(msg.sender, _addresses[i], _amounts[i]);
        }
    }

    // 发送ETH空投：资金先从调用者到合约，再由合约到接收者（合约是 “中转站”）。
    function sendETH(address payable[] calldata _addresses, uint256[] calldata _amounts) external payable{
        require(_addresses.length == _amounts.length, "Length of Addresses and Amounts must be equal");
        uint256 sums = getSum(_amounts);
        require(msg.value==sums, "Need Approve ETH token");
        for(uint8 i;i<_addresses.length;i++){
            _addresses[i].transfer(_amounts[i]);
        }
    }
}