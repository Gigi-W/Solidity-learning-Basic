// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;
contract PaymentSplit{
    uint256 public totalShares; // 总份额
    uint256 public totalReleased; // 总金额
    mapping(address=> uint256) public shares; // 每个受益人的份额
    mapping(address=> uint256) public released; // 每个受益人的金额
    address[] public payees; // 受益人数组

    event PayeeAdded(address account, uint256 shares); // 添加受益人事件
    event PaymentReleased(address to, uint256 amount); // 提款事件
    event PaymentReceived(address from, uint256 amount); // 合约收款事件


    constructor(address[] memory _payees, uint256[] memory _shares) payable{
        require(_payees.length>0, "no payee");
        require(_payees.length == _shares.length, "payees and shares length mismatch");
        for(uint i=0;i<_payees.length;i++){
            _addShares(_payees[i], _shares[i]);
        }
    }

    // 添加受益人
    function _addShares(address account,  uint256 accountShares) private{
        require(shares[account]==0, "account has already shares");
        require(account!=address(0), "account is the zero address");
        require(accountShares>0, "shares are 0");
        
        shares[account]=accountShares;
        totalShares += accountShares;
        payees.push(account);

        emit PayeeAdded(account, accountShares);
    }

    // 合约收款
    receive() external payable virtual{
        emit PaymentReceived(msg.sender, msg.value);
    }

    function release(address payable account) external {
        require(shares[account]>0, "account has no shares");
        // 计算account应得的eth
        uint256 payment = releasable(account);
        require(payment>0, "account is not due payment");
        totalReleased+=payment;
        released[account]+=payment;
        // 转账
        account.transfer(payment);
        emit PaymentReleased(account, payment);
    }

    // 计算一个账户应取得的ETH
    function releasable(address account) view public returns(uint256){
        // 分账合约总收入=未分出去的钱+已分出去的钱
        uint256 totalReceived = address(this).balance + totalReleased;
        return pendingPayment(account, totalReceived, released[account]);
    }

    // 根据受益人地址、合约总收入、该受益人已经领取的钱，计算现在还需要领取多少钱
    function pendingPayment(address _account, uint256 _totalReceived, uint256 _alreadyReleased) view public returns(uint256){
        // shares[_account] / totalShares = x + _alreadyReleased / _totalReceived
        return _totalReceived * shares[_account] / totalShares - _alreadyReleased;
    }
}