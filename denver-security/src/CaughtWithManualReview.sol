// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract CaughtWithManualReview {
    /*
     * @dev adds 2 to numberToAdd and returns it
     */

    ///////////// Given Function /////////////

    // function doMath(uint256 numberToAdd) public pure returns(uint256){
    //     return numberToAdd + 1;
    // }

    function doMath(uint256 numberToAdd) public pure returns (uint256) {
        return numberToAdd + 2;
    }


    // We should write a test for every issue we find during manual review!
}
