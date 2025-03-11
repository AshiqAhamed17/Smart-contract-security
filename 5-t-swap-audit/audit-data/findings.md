
# HIGH

## [H-1] `TSwapPool::deposit` is missing deadline check causing transaction to complete even after the deadline.

### Description:
The `deposit` function accepts a deadline parameter, which according to the documentation is "The deadline for the transaction to be completed by". However, this parameter is never used. As a consequence, operationrs that add liquidity to the pool might be executed at unexpected times, in market conditions where the deposit rate is unfavorable.

<!-- MEV attacks -->

### Impact:
Transactions could be sent when market conditions are unfavorable to deposit, even when adding a deadline parameter.

### Proof of Concept:
The `deadline` parameter is unused.

## Recommended Mitigation:
```diff
function deposit(
        uint256 wethToDeposit,
        uint256 minimumLiquidityTokensToMint, // LP tokens -> if empty, we can pick 100% (100% == 17 tokens)
        uint256 maximumPoolTokensToDeposit,
        uint64 deadline
    )
        external
+       revertIfDeadlinePassed(deadline)
        revertIfZero(wethToDeposit)
        returns (uint256 liquidityTokensToMint)
    {
```

# LOW

## [L-1] Event is missing `indexed` fields

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

## [L-2] `TSwapPool::LiquidityAdded` event is emitted in backwards

The event parameters for emitting is provided wrongly i.e, in a wrong order.

## Recommended Mitigation:

```diff
-   emit LiquidityAdded(msg.sender, poolTokensToDeposit, wethToDeposit);
+   emit LiquidityAdded(msg.sender, wethToDeposit, poolTokensToDeposi);

```


---
---


# INFORMATIONAL

## [I-1] `PoolFactory::PoolFactory__PoolDoesNotExist` is not used and should be removed.

```diff
-   error PoolFactory__PoolDoesNotExist(address tokenAddress);
```

---


## [I-2] Lacking zero address checks

```diff
    constructor(address wethToken) {
+       if(wethToken == address(0)) {
+           revert();
+       }
        i_wethToken = wethToken;
    }
```

## [I-3] `PoolFactory::liquidityTokenSymbol` should use `.symbol()` instead of `.name()`.

```diff
-    string memory liquidityTokenSymbol = string.concat("ts", IERC20(tokenAddress).name());

+    string memory liquidityTokenSymbol = string.concat("ts", IERC20(tokenAddress).symbol());

```

## [I-4] `TSwapPool::poolTokenReserves` is not used and should be removed.

```diff
-   uint256 poolTokenReserves = i_poolToken.balanceOf(address(this));
```

## [I-5] Large literal values multiples of 10000 can be replaced with scientific notation

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

## [I-6] Use of magic numbers in `TSwapPool::getOutputAmountBasedOnInput`

Introduce named constants for the fee percentage and denominator base:

```diff
+   uint256 constant FEE_NUMERATOR = 997;
+   uint256 constant FEE_DENOMINATOR = 1000;

-   uint256 inputAmountMinusFee = inputAmount * 997;
+   uint256 inputAmountMinusFee = inputAmount * FEE_NUMERATOR;

-   uint256 denominator = (inputReserves * 1000) + inputAmountMinusFee;
+   uint256 denominator = (inputReserves * FEE_DENOMINATOR) + inputAmountMinusFee;
```

## [I-7] ``TSwapPool::swapExactInput` function is public can be restricted to external
