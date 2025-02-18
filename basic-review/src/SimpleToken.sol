// SPDX-License_Identifier: MIT
pragma solidity ^0.8.19;

contract SimpleToken {

    uint256 public totalSupply;
    mapping(address => uint256) private balances;
    address private owner;
    string constant private NAME = "SimpleToken";
    string constant private SYMBOL = "ST";

    event Mint(address indexed to, uint256 amount);
    event Burn(address indexed from, uint256 amount);

    constructor(address _owner) {
        owner = _owner;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    function mint(address _to, uint256 _amount) external onlyOwner {
        require(_to != address(0), "Cannot mint to zero address");
        balances[_to] +=_amount;
        totalSupply += _amount;
        emit Mint(_to, _amount);
    }

    function burn(address _from, uint256 _amount) external {
        require(_from != address(0), "Invalid address");
        require(balances[_from] >= _amount, "Insufficient Balance");
        balances[_from] -= _amount;
        totalSupply -= _amount;
        emit Burn(_from, _amount);
    }

    function balanceOf(address user) public view returns (uint256) {
        return balances[user];
    }

    function getTotalSupply() public view returns (uint256) {
        return totalSupply;
    }


    

}