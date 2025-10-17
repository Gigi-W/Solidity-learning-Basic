// SPDX-License-Identifier:MIT
import './ERC721.sol';
pragma solidity ^0.8.21;
contract ERC721Token is ERC721{
    uint public MAX_APES = 10000;

    constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) { }

    // BAYC的baseURI为ipfs://QmeSjSinHpPnmXmspMjwiXyN6zS4E9zccariGR3jxcaWtq/
    function _baseURI() internal pure override returns(string memory){
        return "ipfs://QmeSjSinHpPnmXmspMjwiXyN6zS4E9zccariGR3jxcaWtq/";
    }

    function mint(address to, uint tokenId) external{
        require(tokenId >= 0 && tokenId < MAX_APES, 'tokenId out of range');
        _mint(to, tokenId);
    } 
}