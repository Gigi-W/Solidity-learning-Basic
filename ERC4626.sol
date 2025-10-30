// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {IERC20, ERC20, IERC20Metadata} from "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol";
import {IERC4626} from "./IERC4626.sol";

contract ERC4626 is ERC20, IERC4626{
    ERC20 private immutable _asset; // underlying assets
    uint8 private immutable _decimals;

    constructor(ERC20 asset_, string memory name_, string memory symbol_) ERC20 (name_, symbol_){
        _asset = asset_;
        _decimals = asset_.decimals();
    }

    // meta data
    function asset() public view virtual override returns(address){
        return address(_asset);
    }

    function decimals() public view virtual override returns (uint8){
        return _decimals;
    }


    // deposit/withdraw
    function deposit(uint256 assets, address receiver) public virtual override returns(uint256 shares){
        shares = previewDeposit(assets);
        _asset.transferFrom(msg.sender, address(this), assets);
        _mint(receiver, shares);
        emit Deposit(msg.sender, receiver, assets, shares);
    }

    function mint(uint256 shares, address receiver) public virtual override returns(uint256 assets){
        assets = previewMint(shares);
        _asset.transferFrom(msg.sender, address(this), assets);
        _mint(receiver, shares);
        emit Deposit(msg.sender, receiver, assets, shares);
    }

    function withdraw(uint256 assets, address receiver, address owner) public virtual override returns(uint256 shares){
        shares = previewWithdraw(assets);
        // if sender not owner,then check and update approvals
        if(msg.sender != owner){
            _spendAllowance(owner, msg.sender, shares);
        }
        _burn(owner, shares);
        _asset.transfer(receiver, assets);
        emit Withdraw(msg.sender, receiver, owner, assets, shares);
    }

    function redeem(uint256 shares, address receiver, address owner) public virtual override returns(uint256 assets){
        assets = previewRedeem(shares);
        if(msg.sender!=owner){
            _spendAllowance(owner, msg.sender, shares);
        }
        _burn(owner, shares);
        _asset.transfer(receiver, assets);
        emit Withdraw(msg.sender, receiver, owner, assets, shares);
    }


    function previewDeposit(uint256 assets) public view virtual override returns(uint256){
        return convertToShares(assets);
    }

    function previewMint(uint256 shares) public view virtual override returns(uint256){
        return convertToAssets(shares);
    }

    function previewWithdraw(uint256 assets) public view virtual override returns(uint256){
        return convertToShares(assets);
    }

    function previewRedeem(uint256 shares) public view virtual returns(uint256){
        return convertToAssets(shares);
    }

    function convertToShares(uint256 assets) public view virtual returns(uint256){
        // shares / totalSupply()  = assets / totalAssets
        return totalSupply()==0? assets : assets * totalSupply() / totalAssets();
    }

    function convertToAssets(uint256 shares) public view virtual returns(uint256){
        // shares / totalSupply()  = assets / totalAssets
        return totalSupply() == 0? shares: shares * totalAssets() / totalSupply();
    }

    function totalAssets() public view virtual returns(uint256){
        return _asset.balanceOf(address(this));
    }

    function maxDeposit(address) public view virtual returns (uint256) {
        return type(uint256).max;
    }

    function maxMint(address) public view virtual returns (uint256) {
        return type(uint256).max;
    }

    function maxWithdraw(address owner) public view virtual returns (uint256) {
        return convertToAssets(balanceOf(owner));
    }

    function maxRedeem(address owner) public view virtual returns (uint256) {
        return balanceOf(owner);
    }
}