# Aderyn Analysis Report

This report was generated by [Aderyn](https://github.com/Cyfrin/aderyn), a static analysis tool built by [Cyfrin](https://cyfrin.io), a blockchain security company. This report is not a substitute for manual audit or security review. It should not be relied upon for any purpose other than to assist in the identification of potential security vulnerabilities.
# Table of Contents

- [Summary](#summary)
  - [Files Summary](#files-summary)
  - [Files Details](#files-details)
  - [Issue Summary](#issue-summary)
- [Low Issues](#low-issues)
  - [L-1: Solidity pragma should be specific, not wide](#l-1-solidity-pragma-should-be-specific-not-wide)
  - [L-2: `public` functions not used internally could be marked `external`](#l-2-public-functions-not-used-internally-could-be-marked-external)
  - [L-3: Define and use `constant` variables instead of using literals](#l-3-define-and-use-constant-variables-instead-of-using-literals)
  - [L-4: Event is missing `indexed` fields](#l-4-event-is-missing-indexed-fields)
  - [L-5: PUSH0 is not supported by all chains](#l-5-push0-is-not-supported-by-all-chains)
  - [L-6: Large literal values multiples of 10000 can be replaced with scientific notation](#l-6-large-literal-values-multiples-of-10000-can-be-replaced-with-scientific-notation)
  - [L-7: Unused Custom Error](#l-7-unused-custom-error)


# Summary

## Files Summary

| Key | Value |
| --- | --- |
| .sol Files | 2 |
| Total nSLOC | 350 |


## Files Details

| Filepath | nSLOC |
| --- | --- |
| src/PoolFactory.sol | 35 |
| src/TSwapPool.sol | 315 |
| **Total** | **350** |


## Issue Summary

| Category | No. of Issues |
| --- | --- |
| High | 0 |
| Low | 7 |


# Low Issues

## L-1: Solidity pragma should be specific, not wide

Consider using a specific version of Solidity in your contracts instead of a wide version. For example, instead of `pragma solidity ^0.8.0;`, use `pragma solidity 0.8.0;`

<details><summary>2 Found Instances</summary>


- Found in src/PoolFactory.sol [Line: 15](src/PoolFactory.sol#L15)

	```solidity
	pragma solidity ^0.8.20;
	```

- Found in src/TSwapPool.sol [Line: 15](src/TSwapPool.sol#L15)

	```solidity
	pragma solidity ^0.8.20;
	```

</details>



## L-2: `public` functions not used internally could be marked `external`

Instead of marking a function as `public`, consider marking it as `external` if it is not used internally.

<details><summary>1 Found Instances</summary>


- Found in src/TSwapPool.sol [Line: 298](src/TSwapPool.sol#L298)

	```solidity
	    function swapExactInput(
	```

</details>



## L-3: Define and use `constant` variables instead of using literals

If the same constant literal value is used multiple times, create a constant state variable and reference it throughout the contract.

<details><summary>4 Found Instances</summary>


- Found in src/TSwapPool.sol [Line: 276](src/TSwapPool.sol#L276)

	```solidity
	        uint256 inputAmountMinusFee = inputAmount * 997;
	```

- Found in src/TSwapPool.sol [Line: 295](src/TSwapPool.sol#L295)

	```solidity
	            ((outputReserves - outputAmount) * 997);
	```

- Found in src/TSwapPool.sol [Line: 458](src/TSwapPool.sol#L458)

	```solidity
	                1e18,
	```

- Found in src/TSwapPool.sol [Line: 467](src/TSwapPool.sol#L467)

	```solidity
	                1e18,
	```

</details>



## L-4: Event is missing `indexed` fields

Index event fields make the field more quickly accessible to off-chain tools that parse events. However, note that each index field costs extra gas during emission, so it's not necessarily best to index the maximum allowed per event (three fields). Each event should use three indexed fields if there are three or more fields, and gas usage is not particularly of concern for the events in question. If there are fewer than three fields, all of the fields should be indexed.

<details><summary>4 Found Instances</summary>


- Found in src/PoolFactory.sol [Line: 35](src/PoolFactory.sol#L35)

	```solidity
	    event PoolCreated(address tokenAddress, address poolAddress);
	```

- Found in src/TSwapPool.sol [Line: 52](src/TSwapPool.sol#L52)

	```solidity
	    event LiquidityAdded(
	```

- Found in src/TSwapPool.sol [Line: 57](src/TSwapPool.sol#L57)

	```solidity
	    event LiquidityRemoved(
	```

- Found in src/TSwapPool.sol [Line: 62](src/TSwapPool.sol#L62)

	```solidity
	    event Swap(
	```

</details>



## L-5: PUSH0 is not supported by all chains

Solc compiler version 0.8.20 switches the default target EVM version to Shanghai, which means that the generated bytecode will include PUSH0 opcodes. Be sure to select the appropriate EVM version in case you intend to deploy on a chain other than mainnet like L2 chains that may not support PUSH0, otherwise deployment of your contracts will fail.

<details><summary>2 Found Instances</summary>


- Found in src/PoolFactory.sol [Line: 15](src/PoolFactory.sol#L15)

	```solidity
	pragma solidity ^0.8.20;
	```

- Found in src/TSwapPool.sol [Line: 15](src/TSwapPool.sol#L15)

	```solidity
	pragma solidity ^0.8.20;
	```

</details>



## L-6: Large literal values multiples of 10000 can be replaced with scientific notation

Use `e` notation, for example: `1e18`, instead of its full numeric value.

<details><summary>3 Found Instances</summary>


- Found in src/TSwapPool.sol [Line: 45](src/TSwapPool.sol#L45)

	```solidity
	    uint256 private constant MINIMUM_WETH_LIQUIDITY = 1_000_000_000;
	```

- Found in src/TSwapPool.sol [Line: 294](src/TSwapPool.sol#L294)

	```solidity
	            ((inputReserves * outputAmount) * 10000) /
	```

- Found in src/TSwapPool.sol [Line: 406](src/TSwapPool.sol#L406)

	```solidity
	            outputToken.safeTransfer(msg.sender, 1_000_000_000_000_000_000);
	```

</details>



## L-7: Unused Custom Error

it is recommended that the definition be removed when custom error is unused

<details><summary>1 Found Instances</summary>


- Found in src/PoolFactory.sol [Line: 22](src/PoolFactory.sol#L22)

	```solidity
	    error PoolFactory__PoolDoesNotExist(address tokenAddress);
	```

</details>



