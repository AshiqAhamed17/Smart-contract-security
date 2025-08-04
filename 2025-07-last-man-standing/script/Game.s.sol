// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {Game} from "../src/Game.sol";

contract GameScript is Script {
    function setUp() public {}

    function run() public returns (Game) {
        uint256 initialClaimFee = 0.01 ether;
        uint256 gracePeriod = 3 days;
        uint256 feeIncreasePercentage = 15;
        uint256 platformFeePercentage = 3;

        vm.startBroadcast();

        Game game = new Game(
            initialClaimFee,
            gracePeriod,
            feeIncreasePercentage,
            platformFeePercentage
        );

        vm.stopBroadcast();

        console.log("Game contract deployed to:", address(game));
        console.log("Initial Claim Fee:", initialClaimFee);
        console.log("Grace Period (seconds):", gracePeriod);
        console.log("Fee Increase Percentage:", feeIncreasePercentage);
        console.log("Platform Fee Percentage:", platformFeePercentage);

        return game;
    }
}
