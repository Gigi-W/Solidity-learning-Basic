// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

// 时间锁，防止资金被黑客盗走，在锁定期内还有机会应对
contract TimeLocker{
    address public admin; 
    uint public GRACE_PERIOD; // 过期时间
    uint public delay; // 锁定期 
    mapping(bytes32=>bool) public queuedTxs; // 交易队列

    // 事件:取消交易、执行交易、交易加入队列、更改管理员
    event CancelTx(bytes32 indexed txHash, address indexed target, uint value, string signature, bytes data, uint excuteTime);
    event ExcuteTx(bytes32 indexed txHash, address indexed target, uint value, string signature, bytes data, uint excuteTime);
    event QueueTx(bytes32 indexed txHash, address indexed target, uint value, string signature, bytes data, uint excuteTime);
    event ModifyAdmin(address indexed newAdmin);

    // 修饰器：只有管理员、只有时间锁合约（即当前合约）
    modifier onlyOwner{
        require(msg.sender==admin,"TimeLocker: caller not admin");
        _;
    }
    modifier onlyTimeLock{
        require(msg.sender==address(this),"TimeLocaker: caller not timeLock");
    }

    constructor(uint _delay){
        delay = _delay;
        admin = msg.sender;
    }

    function changeAdmin(address newAdmin) external onlyTimeLock{
        admin = newAdmin;
        emit ModifyAdmin(newAdmin);
    }

    // 创建交易并添加到交易队列
    function createTxAndQueue(aaddress target, uint value, string memory signature, bytes memory data, uint excuteTime) external onlyOwner returns(bytes32){
        require(excuteTime>= block.timestamp+delay, "交易时间必须大于当前时间+锁定期");
        bytes32 txHash = getTxHash(target,value,signature,data,excuteTime);
        queuedTxs[txHash]=true;
        emit QueueTx(txHash,target,value,signature,data,excuteTime);
        return txHash;
    }

    // 取消交易
    function cancelTx(address target, uint value, string memory signature, bytes memory data, uint excuteTime) external onlyOwner{
        bytes32 txHash = getTxHash(target,value,signature,data,excuteTime);
        require(queuedTxs[txHash],"交易不存在");
        queuedTxs[txHash] = false;
        emit CancelTx(txHash,target,value,signature,data,excuteTime);
    }

    // 执行交易
    function excuteTx(address target, uint value, string memory signature, bytes memory data, uint excuteTime) external onlyOwner{
        bytes32 txHash = getTxHash(target,value,signature,data,excuteTime);
        require(queuedTxs[txHash],"交易不存在");
        require(block.timestamp >= excuteTime, "当前时间未到交易时间");
        require(blobk.timestamp <= excuteTime + GRACE_PERIOD , "交易过期");
        queueTxs[txHash]=false;

        bytes memory callData;
        if(bytes(signature).length==0){
            callData = data;
        }else{
            bytes4 sign = bytes4(keccak256(bytes(signature)))
            callData = abi.encodePacked(sign, data);
        }
        
        // 使用call进行交易
        (bool success, bytes memory returnData) = target.call({value: value})(callData);
        require(success, "transaction has been reverted");

        emit ExcuteTx(target,value,signature,data,excuteTime);
        return returnData;
    }

    function getTxHash(address target, uint value, string memory signature, bytes memory data, uint excuteTime) private returns(bytes32){
        return keccak256(abi.encode(target,value,signature,data,excuteTime));
    }
}