// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/CaughtWithManualReview.sol";

contract CaughtWithManualReviewTest is Test {
    CaughtWithManualReview c;

    function setUp() public {
        c = new CaughtWithManualReview();
    }

    /// @notice Unit test for doMath function
    function testDoMath() public {
        uint256 input = 17;
        uint256 expected = input + 2;
        assertEq(c.doMath(input), expected, "Incorrect addition logic");
    }

    /// @notice Edge case tests
    function testdoMathWithMaxUintValue() public {
        uint256 input = type(uint256).max - 2;
        uint256 expected = type(uint256).max;

        assertEq(c.doMath(input), expected, "Failed on max uint256 value");
    }

    /// @notice Fuzz test to check correctness on random inputs
    function testFuzzDoMath(uint256 input) public {
        
    }


}