// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;
// 导入 OpenZeppelin 的 ERC20 合约（最新版本）
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.9.3/contracts/token/ERC20/IERC20.sol";

contract MyERC20 is IERC20{
    // /**
    //  * 转账事件(IERC20已实现)
    //  */
    // event Transfer(address from, address to, uint256 value);
    // /**
    //  * 授权事件(IERC20已实现)
    //  */
    // event Approval(address owner, address spender, uint256 value);

    address public owner;

    // 定义owner修饰器
    modifier onlyOwner{
        require(msg.sender == owner, "Only owner can operate");
        _;
    }

    // 定义标准状态变量：账户余额、授权额度、代币总供给
    mapping(address => uint256) public override balanceOf;
    mapping(address => mapping(address=>uint256)) public override allowance;
    uint256 public override totalSupply;

    // 定义代币名称、代号、小数位数
    string public name;
    string public symbol;
    uint8 public decimals = 18;

    // 初始化代币名称、代号
    constructor(string memory name_,string memory symbol_){
        owner = msg.sender;
        name = name_;
        symbol = symbol_;
    }

    // 实现转账
    function transfer(address recipient, uint256 amount) public override returns(bool){
        require(amount > 0, "Amount must greater than 0");
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");
        // 使用uncheck节省gas
        unchecked {
            balanceOf[msg.sender] -= amount;
        }
        balanceOf[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    // 实现授权
    function approve(address spender, uint256 amount) public override returns(bool){
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender,spender,amount);
        return true;
    }

    // 实现授权转账
    function transferFrom(address sender, address recipient, uint256 amount) public override returns(bool){
        require(amount > 0, "Amount must be greater than 0");
        require(allowance[sender][msg.sender]>=amount, "Insufficient allowance");
        allowance[sender][msg.sender] -=amount;
        balanceOf[sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    // 铸造代币函数：一般是铸给部署者
    function mint(uint256 amount) external onlyOwner{
        balanceOf[msg.sender] += amount;
        totalSupply += amount;
        emit Transfer(address(0), msg.sender, amount);
    }

    // 销毁代币函数
    function burn(uint256 amount) external onlyOwner{
        balanceOf[msg.sender] -= amount;
        totalSupply -= amount;
        emit Transfer(msg.sender, address(0), amount);
    }
}