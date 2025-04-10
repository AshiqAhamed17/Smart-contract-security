// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.20;


// e this is probably the interface of the PoolFactory.sol
interface IPoolFactory {
    function getPool(address tokenAddress) external view returns (address);
    
}
