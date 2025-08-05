// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

error CornInvalidAmount();
error CornInsufficientBalance();
error CornInsufficientAllowance();
error CornInvalidAddress();

contract Corn is ERC20, Ownable {
    constructor() ERC20("CORN", "CORN") Ownable(msg.sender) {}

    function burnFrom(address account, uint256 amount) external onlyOwner returns (bool) {
        uint256 balance = balanceOf(account);
        if (amount == 0) {
            revert CornInvalidAmount();
        }
        if (balance < amount) {
            revert CornInsufficientBalance();
        }
        _burn(account, amount);
        return true;
    }

    function mintTo(address to, uint256 amount) external onlyOwner returns (bool) {
        if (to == address(0)) {
            revert CornInvalidAddress();
        }
        if (amount == 0) {
            revert CornInvalidAmount();
        }
        _mint(to, amount);
        return true;
    }
}