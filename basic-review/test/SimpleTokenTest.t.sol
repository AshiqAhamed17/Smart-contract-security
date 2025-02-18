// SPDX-License_Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "forge-std/StdInvariant.sol";
import "../src/SimpleToken.sol";


contract SimpleTokenTest is Test {
    SimpleToken token;
    address user1 = vm.addr(1);
    address user2 = vm.addr(2);

    function setUp() public {

        token = new SimpleToken(user1);
        targetContract(address(token));
    }

    /////////// Fuzz Tests ///////////////


    ///@notice Fuzz test for mint function
    function testFuzzMint(address _to, uint256 _amount) public {
        vm.assume(_to != address(0));

        vm.deal(user1, 100);
        vm.prank(user1);
        token.mint(_to, _amount);

        assertEq(token.balanceOf(_to), _amount, "Mismatch in amount");
        assertEq(token.totalSupply(), _amount);

    }

    ///@notice Fuzz test for burn function
    function testFuzzBurn(address _from, uint256 _amount) public {
        vm.assume(_from != address(0));
        vm.assume(token.balanceOf(_from) >= _amount);
        token.burn(_from, _amount);
        assertEq(token.balanceOf(_from), 0);
        assertEq(token.getTotalSupply(), 0);
    }

    /////////// Invariant Tests ///////////////

    ///@notice  Ensure totalSupply is never negative
    function invariant_TotalSupplyNeverNegative() public view {
        assert(token.getTotalSupply() >= 0);
    }

}