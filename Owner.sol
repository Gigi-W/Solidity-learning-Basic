// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;
contract Owner{
    address public owner;
    constructor(address initOwner){
        owner = initOwner;
    }

    modifier onlyOwner{
        require(msg.sender==owner);
        _;
    }

    function changeOwner(address _newOwner) public onlyOwner{
        owner = _newOwner;
    }
}