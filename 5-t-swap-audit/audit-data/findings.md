
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
---
---


## [H-2] Incorrect fee calculation in `TSwapPool::getInputAmountBasedOnOutput` causes protocll to take too many tokens from users, resulting in lost fees

### Description:
The getInputAmountBasedOnOutput function is intended to calculate the amount of tokens a user should deposit given an amount of tokens of output tokens. However, the function currently miscalculates the resulting amount. When calculating the fee, it scales the amount by 10_000 instead of 1_000.

### Impact:
 Protocol takes more fees than expected from users.

## Recommended Mitigation:

```diff
    function getInputAmountBasedOnOutput(
        uint256 outputAmount,
        uint256 inputReserves,
        uint256 outputReserves
    )
        public
        pure
        revertIfZero(outputAmount)
        revertIfZero(outputReserves)
        returns (uint256 inputAmount)
    {
-        return ((inputReserves * outputAmount) * 10_000) / ((outputReserves - outputAmount) * 997);
+        return ((inputReserves * outputAmount) * 1_000) / ((outputReserves - outputAmount) * 997);
    }
```
---
---

## [H-3] Lack of slippage protection in `TSwapPool::swapExactOutput` causes users to potentially receive way fewer tokens

### Description:
The `swapExactOutput` function does not include any sort of slippage protection. This function is similar to what is done in `TSwapPool::swapExactInput`, where the function specifies a `minOutputAmount`, the `swapExactOutput` function should specify a `maxInputAmount`. 

### Impact:
If market conditions change before the transaciton processes, the user could get a much worse swap.

### Proof of Concept:
1. User inputs a 

### Recommended Mitigation:





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

## [L-2] `TSwapPool::LiquidityAdded` event has wrong order of parameters

## Description
When the LiquidityAdded event is emitted in the TSwapPool::_addLiquidityMintAndTransfer function, it logs values in an incorrect order. The poolTokensToDeposit value should go in the third parameter position, whereas the wethToDeposit value should go second.

## Impact
 Event emission is incorrect, leading to off-chain functions potentially malfunctioning.

## Recommended Mitigation:

```diff
-   emit LiquidityAdded(msg.sender, poolTokensToDeposit, wethToDeposit);
+   emit LiquidityAdded(msg.sender, wethToDeposit, poolTokensToDeposi);

```

## [L-3]  Default value returned by `TSwapPool::swapExactInput` results in incorrect return value given

### Description:
The `swapExactInput` function is expected to return the actual amount of tokens bought by the caller. However, while it declares the named return value `output` it is never assigned a value, nor uses an explict return statement.

### Impact:
 The return value will always be 0, giving incorrect information to the caller.


## Recommended Mitigation:

```diff
{
        uint256 inputReserves = inputToken.balanceOf(address(this));
        uint256 outputReserves = outputToken.balanceOf(address(this));

-        uint256 outputAmount = getOutputAmountBasedOnInput(inputAmount, inputReserves, outputReserves);
+        output = getOutputAmountBasedOnInput(inputAmount, inputReserves, outputReserves);

-        if (output < minOutputAmount) {
-            revert TSwapPool__OutputTooLow(outputAmount, minOutputAmount);
+        if (output < minOutputAmount) {
+            revert TSwapPool__OutputTooLow(outputAmount, minOutputAmount);
        }

-        _swap(inputToken, inputAmount, outputToken, outputAmount);
+        _swap(inputToken, inputAmount, outputToken, output);
}
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

## [I-7] `TSwapPool::swapExactInput` `public` functions not used internally could be marked `external`

Instead of marking a function as `public`, consider marking it as `external` if it is not used internally.

<details><summary>1 Found Instances</summary>


- Found in src/TSwapPool.sol [Line: 298](src/TSwapPool.sol#L298)

    ```solidity
        function swapExactInput(
    ```

</details>