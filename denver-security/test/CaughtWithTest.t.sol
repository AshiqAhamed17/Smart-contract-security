// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/CaughtWithTest.sol";

contract CaughtWithTestTest is Test {
    CaughtWithTest public caughtWithTest;

    function setUp() public {
        caughtWithTest = new CaughtWithTest();
    }

    ///@notice Unit test
    function testSetNumber() public {
        uint256 myNumber = 55;
        caughtWithTest.setNumber(myNumber);
        uint256 expectedNumber = caughtWithTest.number();
        assertEq(myNumber ,expectedNumber, "Number mismatch");
    }

    ///@notice Fuzz test to check the correctness of the code
    function testFuzzSetNumber(uint256 num) public {
        caughtWithTest.setNumber(num);
        uint256 expectedNum = caughtWithTest.number();
        assertEq(num, expectedNum, "Fuzz test mismatch");
    }
}
