// SPDX-License-Identifier:MIT
import './ERC1155.sol';
pragma solidity ^0.8.21;
contract ERC1155Token is ERC1155{
    uint public MAX_ID = 10000;

    constructor(string memory name_, string memory symbol_) ERC1155(name_, symbol_) { }

    // BAYC的baseURI为ipfs://QmeSjSinHpPnmXmspMjwiXyN6zS4E9zccariGR3jxcaWtq/
    function _baseURI() internal pure override returns(string memory){
        return "ipfs://QmeSjSinHpPnmXmspMjwiXyN6zS4E9zccariGR3jxcaWtq/";
    }

    function mint(address to, uint id, uint amount) external{
        require(id >= 0 && id < MAX_ID, 'tokenId out of range');
        _mint(to, id,amount,"");
    } 

    function batchMint(address to, uint[] memory ids, uint[] memory amounts) external{
        // id 不能超过10,000
        for (uint256 i = 0; i < ids.length; i++) {
            require(ids[i]>=0 && ids[i] < MAX_ID, "id overflow");
        }
        _batchMint(to, ids, amounts,"");
    }
}