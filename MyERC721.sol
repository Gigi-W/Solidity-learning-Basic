// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.9.3/contracts/utils/introspection/IERC165.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.9.3/contracts/token/ERC721/IERC721.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.9.3/contracts/token/ERC721/IERC721Receiver.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.9.3/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.9.3/contracts/utils/Strings.sol";

contract MyERC721 is IERC721, IERC721Metadata{
    using Strings for uint256; 
    
    string public override name;
    string public override symbol;

    mapping(uint256 => address) private _owners; // 代币到持有人映射 
    mapping(uint256 => address) private _tokenApprovals; // 代币到授权地址映射
    mapping(address => uint256) private _balances; // 持仓数量映射
    mapping(address => mapping(address => bool)) private _operatorApprovals; // 批量授权映射[所有者][操作者]=是否授权

    error ERC721InvalidReceiver(address receiver); // 无效接收者

    constructor(string memory name_, string memory symbol_){
        name = name_;
        symbol = symbol_;
    }

    // 实现IERC165 supportsInterface，查询合约是否支持了IERC721、IERC165、IERC721Metadata的接口
    function supportsInterface(bytes4 interfaceId) external pure override returns(bool){
        return interfaceId == type(IERC721).interfaceId || interfaceId == type(IERC165).interfaceId || interfaceId == type(IERC721Metadata).interfaceId;
    }

    // 查询代币是谁的
    function ownerOf(uint tokenId) public view override returns(address owner){
        owner = _owners[tokenId];
        require(owner!=address(0), 'owner = zero address');
    }

    // 查询代币被授权者是谁
    function getApproved(uint tokenId) external view override returns(address operator){
        operator = _tokenApprovals[tokenId];
        require(operator!=address(0), 'operator = zero address');
    }

    // 查询拥有者拥有的代币数量
    function balanceOf(address owner) external view override returns(uint){
        require(owner!=address(0), 'owner = zero address');
        return _balances[owner];
    }
 
    // 查询owner是否批量授权给了operator
    function isApprovedForAll(address owner, address operator) external view override returns(bool){
        return _operatorApprovals[owner][operator];
    }


    // 调用者批量授权给operator地址
    function setApprovalForAll(address operator, bool approved) external override{
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    // 授权，私有函数
    function _approve(address owner, address to, uint tokenId) private {
        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    // 授权，调用私有授权函数
    function approve(address to, uint tokenId) external override{
        address owner = _owners[tokenId];
        require(msg.sender==owner || _operatorApprovals[owner][msg.sender], "not owner nor approved for all"); // 调用者必须是owner或授权地址
        _approve(owner, to, tokenId);
    }

    // 私有函数，判断调用者是否是owner或被授权，否则没有资格
    function _isApprovedOrOwner(address owner, address spender, uint tokenId) private view returns(bool){
        return (spender == owner || _tokenApprovals[tokenId]==spender || _operatorApprovals[owner][spender]);
    }

    // 私有函数，转账
    function _transfer(address owner, address from, address to, uint tokenId) private{
        require(from==owner, 'not owner'); // 转账账户必须是owner
        require(to!=address(0), 'transfer to the zero address');
        _approve(owner, address(0), tokenId); // 清除原授权关系，否则可能出现原授权方仍然能操作已转移的NFT的安全问题
        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;
        emit Transfer(from, to, tokenId);
    }

    // 普通转账
    function transferFrom(address from, address to, uint tokenId) external override{
        address owner = ownerOf(tokenId);
        require(_isApprovedOrOwner(owner, msg.sender, tokenId), 'not owner nor approved'); // 转账调用者必须是owner或approved
        _transfer(owner, from, to, tokenId);
    }

    // 私有函数，验证目标合约是否 “懂得如何接收 NFT”
    function _checkOnERC721Received(address from, address to, uint tokenId, bytes memory data) private{
        if(to.code.length>0){
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data) returns(bytes4 retval){
                if(retval!=IERC721Receiver.onERC721Received.selector){ // 实现了但是返回值不匹配
                    revert ERC721InvalidReceiver(to);
                }
            }catch(bytes memory reason){
                if(reason.length==0){ // 未实现onERC721Received
                    revert ERC721InvalidReceiver(to);
                }else{ // 实现了且主动抛出错误，以下为汇编代码
                    /// @solidity memory-safe-assembly
                    assembly {
                        // 内容从32,reason开始，长度为mload(reason)
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        }
    }

    // 私有函数，安全转账
    function _safeTransfer(address owner, address from, address to, uint tokenId, bytes memory _data) private{
        _transfer(owner, from, to, tokenId);
        _checkOnERC721Received(from, to, tokenId, _data);
    }

    // 安全转账
    function safeTransferFrom(address from, address to, uint tokenId, bytes memory _data) public override{
        address owner = ownerOf(tokenId);
        require(_isApprovedOrOwner(owner,msg.sender,tokenId),'not owner nor approved');
        _safeTransfer(owner, from, to, tokenId, _data);
    }

    // 安全转账重载函数
    function safeTransferFrom(address from, address to, uint tokenId) external override{
        safeTransferFrom(from, to, tokenId, "");
    }

    // 铸币函数
    function _mint(address to, uint tokenId) internal virtual{
        require(to!=address(0), 'Mint: zero address');
        require(_owners[tokenId]!=to, 'Token has already exsit');
        _balances[to] += 1;
        _owners[tokenId]=to;
        emit Transfer(address(0), to, tokenId);
    }

    // 毁币函数
    function _burn(uint tokenId) internal virtual{
        address owner = ownerOf(tokenId);
        require(msg.sender==owner,'Only owner can burn token');
        _approve(owner, address(0), tokenId);
        _balances[owner] -= 1;
        delete _owners[tokenId];
        emit Transfer(owner,address(0),tokenId);
    }

    // token的baseURI
    function _baseURI() internal view virtual returns(string memory){
        return "";
    }

    // 实现tokenURI，查询metadata
    function tokenURI(uint tokenId) public view virtual override returns(string memory){
        require(_owners[tokenId]!=address(0), 'Token not exsit');
        string memory baseURI = _baseURI();
        return bytes(baseURI).length>0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }
}