// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/CaughtWithFuzz.sol";

contract CaughtWithFuzzTest is Test {
    CaughtWithFuzz public c;

    function setUp() public {
        c = new CaughtWithFuzz();
    }

    function testFuzz(uint256 randomNumber) public view {
        uint256 returnedNumber = c.doMoreMath(randomNumber);
        assert(returnedNumber != 0);
    }
}
