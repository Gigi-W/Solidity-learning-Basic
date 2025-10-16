// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.9.3/contracts/token/ERC721/IERC721.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.9.3/contracts/token/ERC721/IERC721Receiver.sol";

// NTF交易所
contract NFTSwap is IERC721Receiver{
    // 卖家挂单
    event List(address indexed seller, address indexed nftAddr, uint indexed tokenId, uint price);
    // 卖家撤单
    event Revoke(address indexed seller, address indexed ntfAddr, uint indexed tokenId);
    // 卖家更新价格
    event Update(address indexed seller, address indexed ntfAddr, uint indexed tokenId, uint newPrice);
    // 买家购买
    event Purchase(address buyer, address nftAddr, uint tokenId);

    struct Order{
        address owner;
        uint price;
    }
    mapping(address => mapping(uint=> Order)) public nftList;

    // 实现IERC721Receiver的onERC721Received，能够接收ERC721代币
    function onERC721Received(address,address,uint,bytes calldata) external pure override returns (bytes4){
        return IERC721Receiver.onERC721Received.selector;
    }


    /**
    *   挂单：设置owner和price，将nft转给当前合约
    *   @param _nftAddr nft合约地址
    *   @param _tokenId nft的tokenId
    *   @param _price 挂单价格
    */
    function list(address _nftAddr, uint _tokenId, uint _price) external{
        IERC721 _nft = IERC721(_nftAddr);
        require(_nft.getApproved(_tokenId)==address(this), 'Need Approval'); // 当前合约得到授权
        require(_price>0, 'price must greater than 0'); // 价格大于0

        Order storage _order = nftList[_nftAddr][_tokenId];
        _order.owner = msg.sender;
        _order.price = _price;
        _nft.safeTransferFrom(msg.sender, address(this), _tokenId);

        emit List(msg.sender, _nftAddr, _tokenId, _price);
    }

    /**
    * 撤单：把nft转回去，从nftList删除这个order
    * @param _nftAddr nft合约地址
    * @param _tokenId nft的tokenId
    */
    function revoke(address _nftAddr, uint _tokenId) external{
        Order storage _order = nftList[_nftAddr][_tokenId];
        require(_order.owner==msg.sender, 'Not owner'); // 操作者必须是订单的owner

        IERC721 _nft = IERC721(_nftAddr);
        require(_nft.ownerOf(_tokenId)==address(this), 'Invaid Order'); // 当前合约有这个nft

        _nft.safeTransferFrom(address(this), msg.sender, _tokenId);
        delete nftList[_nftAddr][_tokenId];

        emit Revoke(msg.sender, _nftAddr, _tokenId);
    }

    /**
    * 更新：更新价格
    * @param _nftAddr nft合约地址
    * @param _tokenId nft的tokenId
    * @param _newPrice 新价位
    */
    function update(address _nftAddr, uint _tokenId, uint _newPrice) external{
        Order storage _order = nftList[_nftAddr][_tokenId];
        require(_order.owner==msg.sender, 'Not Owner'); // 订单的owner才可以更新
        require(_newPrice>0, 'New price must greater than 0'); // 新价格大于0
         
        IERC721 _nft = IERC721(_nftAddr);
        require(_nft.ownerOf(_tokenId)==address(this), 'Invalid'); // nft必须在当前合约

        _order.price = _newPrice;
        emit Update(msg.sender, _nftAddr, _tokenId, _newPrice);
    }


    /**
    * 购买：把NFT转给调用者（买家），买家付款给订单的owner（卖家），给合约多的钱退给调用者
    * @param _nftAddr nft合约地址
    * @param _tokenId nft的tokenId
    */
    function purchase(address _nftAddr, uint _tokenId) external payable{
        Order storage _order = nftList[_nftAddr][_tokenId];
        require(msg.value>=_order.price, 'Not enougth'); // 付款大于等于价格
        IERC721 _nft = IERC721(_nftAddr);
        require(_nft.ownerOf(_tokenId)==address(this), 'Invalid'); // NFT必须在当前合约中

        _nft.safeTransferFrom(address(this), msg.sender, _tokenId);
        payable(_order.owner).transfer(_order.price);

        if(msg.value > _order.price){
            payable(msg.sender).transfer(msg.value - _order.price);
        }
        delete nftList[_nftAddr][_tokenId];

        emit Purchase(msg.sender, _nftAddr, _tokenId);
    }
}