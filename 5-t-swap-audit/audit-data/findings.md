
# HIGH

## [H-1] `TSwapPool::deposit` is missing deadline check causing transaction to complete even after the deadline.

### Description:

### Impact:

### Proof of Concept:

## Recommended Mitigation:


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
