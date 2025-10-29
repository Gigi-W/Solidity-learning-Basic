// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

contract MulWallet{
    address[] public owners; // 多签持有人
    uint256 public threshold; // 多签阈值
    uint256 public ownerCount; // 多签持有人数量
    mapping(address=> bool) public isOwner; // 多签持有人映射
    uint256 public nonce; // 交易递增值，防止重放攻击

    constructor(address[] memory _owners, uint256 _threshold) payable{
        setupOwners(_owners, _threshold);
    }

    function setupOwners(address[] memory _owners, uint256 _threshold) internal{
        require(threshold == 0, "WTF5000");
        require(_owners.length > 0, "no owner");
        require(_threshold>=1 && _threshold<=_owners.length, "threshold length incorrectly");
        for(uint256 i=0;i<_owners.length;i++){
            address owner = _owners[i];
            require(owner!=address(0) && owner!=address(this) && !isOwner[owner],"WTF5003"); // 多签人不能为0地址，本合约地址，不能重复
            owners.push(owner);
            isOwner[owner]=true;
        }
        ownerCount = _owners.length;
        threshold = _threshold;
    }

    // 验证签名，执行交易
    function execTx(address to, uint256 value, bytes memory data, bytes memory signatures) public payable returns(bool success){
        bytes32 dataHash = encodeTransactionData(to,value,data,nonce,block.chainid);
        checkSignature(dataHash, signatures);
        nonce++;
        (success, ) = to.call{value: value}(data);
        require(success, "execTx: call failed");
    }

    // 编码交易数据
    function encodeTransactionData(address to, uint256 value, bytes memory data, uint256 _nonce,uint256 chainId) public pure returns(bytes32){
        return keccak256(abi.encode(
            to,value,keccak256(data),_nonce,chainId
        ));
    }

    // 验证并交易
    function checkSignature(bytes32 dataHash, bytes memory signatures) private view{
        uint256 _threshold = threshold;
        require(_threshold > 0);
        require(signatures.length>=_threshold*65);
        
        address currentOwner = address(0);
        address lastOwner;
        bytes32 r;
        bytes32 s;
        uint8 v;
        for(uint i=0;i<_threshold;i++){
            (r,s,v) = signatureSplit(signatures, i);
            // 还原公钥
            currentOwner = ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", dataHash)), v, r, s);
            require(currentOwner > lastOwner && isOwner[currentOwner]);
            lastOwner = currentOwner;
        }
    }

    function signatureSplit(bytes memory signatures, uint256 pos) internal pure returns(bytes32 r,bytes32 s, uint8 v){
        assembly{
            let signaturePos := mul(0x41, pos) // 相当于65 * 0、65 * 1 ...
            r := mload(add(signatures, add(signaturePos, 0x20))) // 这里r起始位置从0x20开始，是因为r之前还有一个空位，占了32字节
            s := mload(add(signatures, add(signaturePos, 0x40)))
            v := and(mload(add(signatures, add(signaturePos, 0x41))), 0xff)
        }
    }
}