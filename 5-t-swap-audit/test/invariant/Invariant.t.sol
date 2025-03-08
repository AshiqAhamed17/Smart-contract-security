// SPDX-License-Identifier: GNU General Public License v3.0
pragma solidity ^0.8.20;


import {Test} from "forge-std/Test.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";
import {ERC20Mock} from "../mocks/ERC20Mock.sol";
import {PoolFactory} from "../../src/PoolFactory.sol";
import {TSwapPool} from "../../src/TSwapPool.sol";


contract Invaraint is StdInvariant, Test {
    // These pool has two assets 1.Any ERC20 2. Weth
    ERC20Mock poolToken;
    ERC20Mock weth;

    //Contracts
    PoolFactory factory;
    TSwapPool pool; // Pool token / Weth

    int256 constant STARTING_X = 100e18; // Starting ERC20/poolToken
    int256 constant STARTING_Y = 5e18; // Starting WETH


    function setUp() public {
        weth = new ERC20Mock();
        poolToken = new ERC20Mock();
        factory = new PoolFactory(address(weth));
        pool = TSwapPool(factory.createPool(address(poolToken)));

        // Create those initial x & y  balances
        poolToken.mint(address(this), uint256(STARTING_X));
        weth.mint(address(this), uint256(STARTING_Y));

        poolToken.approve(address(pool), type(uint256).max);
        weth.approve(address(pool), type(uint256).max);

        // Deposit into pool with the given starting x & y balances
        pool.deposit(
            uint256(STARTING_Y),
            uint256(STARTING_Y),
            uint256(STARTING_X),
            uint64(block.timestamp)
        );
    }
    
    // Normal Invariant
    // x * y = k
    // x * y = (x + ∆x) * (y − ∆y)
    // x = Token Balance X
    // y = Token Balance Y
    // ∆x = Change of token balance X
    // ∆y = Change of token balance Y
    // β = (∆y / y)
    // α = (∆x / x)

    // Final invariant equation without fees:
    // ∆x = (β/(1-β)) * x
    // ∆y = (α/(1+α)) * y

    // Invariant with fees
    // ρ = fee (between 0 & 1, aka a percentage)
    // γ = (1 - p) (pronounced gamma)
    // ∆x = (β/(1-β)) * (1/γ) * x
    // ∆y = (αγ/1+αγ) * y


}