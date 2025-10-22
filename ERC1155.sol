// SPDX-License-Identifier:MIT
pragma solidity ^0.8.21;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v5.0.1/contracts/token/ERC1155/IERC1155.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v5.0.1/contracts/token/ERC1155/IERC1155Receiver.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v5.0.1/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v5.0.1/contracts/utils/Strings.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v5.0.1/contracts/interfaces/IERC165.sol";

contract ERC1155 is IERC165, IERC1155, IERC1155MetadataURI{
    using Strings for uint256; // 将 String 库中的函数，附加到 string 类型上

    string public name;
    string public symbol;
    mapping(uint256=> mapping(address=> uint256)) private _balances; // 代币种类id到账户余额的映射
    mapping(address=> mapping(address=> bool)) private _operatorApprovals; // 批量授权映射

    constructor(string memory _name, string memory _symbol){
        name = _name;
        symbol = _symbol;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns(bool){
        return 
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            interfaceId == type(IERC165).interfaceId;
    }

    // 查询持仓，返回account地址的id种类代币持仓量
    function balanceOf(address account,uint id) public view virtual override returns(uint){
        require(account!=address(0),'0 address');
        return _balances[id][account];
    }

    // 批量持仓查询，accounts和ids一一对应
    function balanceOfBatch(address[] memory accounts, uint[] memory ids) public view virtual override returns(uint[] memory){
        require(accounts.length==ids.length, 'accounts and ids length mismatch'); // accounts必须和ids长度相等
        uint[] memory batchBalances = new uint[](accounts.length);
        for(uint i=0;i<accounts.length;i++){
            batchBalances[i]=balanceOf(accounts[i], ids[i]);
        }
        return batchBalances;
    }

    // 批量授权，调用者授权operator所有代币
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(msg.sender!=operator, 'setting approval status for self');
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    // 查询批量授权
    function isApprovedForAll(address account, address operator) public view virtual override returns(bool){
        return _operatorApprovals[account][operator];
    }

    // ERC1155的安全检查
    function _doSafeTransferAcceptanceCheck(address operator, address form, address to, uint id,uint amount,bytes memory data) private {
        if(to.code.length>0){
            try IERC1155Receiver(to).onERC1155Received(operator,form,id,amount,data) returns (bytes4 response){
                if(response!=IERC1155Receiver.onERC1155Received.selector){
                    revert('reject tokens');
                }
            }catch Error(string memory reason){
                revert(reason);
            }catch {
                revert('transfer to non-ERC1155Receiver implementer');
            }
        }
    }  

    // 安全转账
    function safeTransferFrom(address from, address to,  uint id,uint amount,bytes memory data) external virtual override{
        address operator = msg.sender;
        require(from==operator || isApprovedForAll(from, operator), 'operator must be owner or approved');
        require(from!=to, 'from and to cannot be equal');
        require(to!=address(0), 'to cannot be 0 address');
        uint fromBalance = balanceOf(from, id);
        require(fromBalance>=amount, "insufficient balance for transfer");
        unchecked{
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;
        emit TransferSingle(operator,from,to,id,amount);
        _doSafeTransferAcceptanceCheck(operator,from,to,id,amount,data);
    }

    // ERC1155的批量安全转账检查
    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.code.length>0) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non-ERC1155Receiver implementer");
            }
        }
    }

    // 批量安全转账
    function safeBatchTransferFrom(address from, address to, uint[] memory ids, uint[] memory amounts,bytes memory data) external virtual override{
        address operator = msg.sender;
        require(from==operator || isApprovedForAll(from, operator), 'operator must be owner or approved');
        require(from!=to, 'from and to cannot be equal');
        require(to!=address(0), 'to cannot be 0 address');
        require(ids.length==amounts.length, "ids and amounts length mismatch");
        for(uint i=0;i<ids.length;i++){
            uint amount = amounts[i];
            uint id = ids[i];
            uint fromBalance = balanceOf(from,id);
            require(fromBalance>=amount, "insufficient balance for transfer");
            unchecked{
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }
        emit TransferBatch(operator,from,to,ids,amounts);
        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);   
    }

    // 铸币
    function _mint(address to, uint256 id, uint256 amount, bytes memory data) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        address operator = msg.sender;
        _balances[id][to]+=amount;
        emit TransferSingle(operator, address(0), to, id, amount);
        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    // 批量铸币
    function _batchMint(address to, uint[] memory ids, uint[] memory amounts, bytes memory data) internal virtual{
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length==amounts.length, "ids and amounts length mismatch");
        address operator = msg.sender;
        for(uint i = 0;i<ids.length;i++){
            uint id = ids[i];
            uint amount = amounts[i];
            _balances[id][to] += amount;
        }
         emit TransferBatch(operator, address(0), to, ids, amounts);
        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    // 销毁
    function _burn(address from, uint id, uint amount) internal virtual{
        require(from != address(0), "ERC1155: burn from the zero address");
        uint fromBalance = balanceOf(from,id);
        require(fromBalance >= amount, "balance  must be greater then burn amount");
        unchecked{
            _balances[id][from] = fromBalance - amount;
        }
        emit TransferSingle(msg.sender, from, address(0), id, amount);
    }

    // 批量销毁
    function _batchBurn(address from, uint[] memory ids, uint[] memory amounts) internal virtual{
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length==amounts.length, "ids and amounts length mismatch");
        for(uint i = 0;i<ids.length;i++){
            uint id = ids[i];
            uint amount = amounts[i];
            uint fromBalance = balanceOf(from,id);
            require(fromBalance >= amount, "balance  must be greater then burn amount");
            unchecked{
                _balances[id][from] = fromBalance - amount;
            }
        }
        emit TransferBatch(msg.sender, from, address(0), ids, amounts);
    }

    // 获取id的uri，存储metadata
    function uri(uint id) public view virtual override returns(string memory){
        string memory baseURI = _baseURI();
        return bytes(baseURI).length>0?string(abi.encodePacked(baseURI, id.toString())):"";
    }

    function _baseURI() internal view virtual returns(string memory){
        return "";
    }
}