# First Flight #45: Last Man Standing Game

## Contest Details

Starts: July 31, 2025 Noon UTC

Ends: August 06, 2025 Noon UTC

### Stats

nSLOC: 181


[//]: # (contest-details-open)

## About the Project

The Last Man Standing Game is a decentralized "King of the Hill" style game implemented as a Solidity smart contract on the Ethereum Virtual Machine (EVM). It creates a competitive environment where players vie for the title of "King" by paying an increasing fee. The game's core mechanic revolves around a grace period: if no new player claims the throne before this period expires, the current King wins the entire accumulated prize pot.

## Actors

This protocol includes the following roles:

### 1. Owner (Deployer)
**Powers:**
* Deploys the `Game` contract.
* Can update game parameters: `gracePeriod`, `initialClaimFee`, `feeIncreasePercentage`, `platformFeePercentage`.
* Can `resetGame()` to start a new round after a winner has been declared.
* Can `withdrawPlatformFees()` accumulated from claims.
**Limitations:**
* Cannot claim the throne if they are already the current king.
* Cannot declare a winner before the grace period expires.
* Cannot reset the game if a round is still active.

### 2. King (Current King)
**Powers:**
* The last player to successfully `claimThrone()`.
* Receives a small payout from the next player's `claimFee` (if applicable).
* Wins the entire `pot` if no one claims the throne before the `gracePeriod` expires.
* Can `withdrawWinnings()` once declared a winner.
**Limitations:**
* Must pay the current `claimFee` to become king.
* Cannot claim the throne if they are already the current king.
* Their reign is temporary and can be overthrown by any other player.

### 3. Players (Claimants)
**Powers:**
* Can `claimThrone()` by sending the required `claimFee`.
* Can become the `currentKing`.
* Can potentially win the `pot` if they are the last king when the grace period expires.
**Limitations:**
* Must send sufficient ETH to match or exceed the `claimFee`.
* Cannot claim if the game has ended.
* Cannot claim if they are already the current king.

### 4. Anyone (Declarer)
**Powers:**
* Can call `declareWinner()` once the `gracePeriod` has expired.
**Limitations:**
* Cannot declare a winner if the grace period has not expired.
* Cannot declare a winner if no one has ever claimed the throne.
* Cannot declare a winner if the game has already ended.

[//]: # (contest-details-close)

[//]: # (scope-open)

## Scope

```bash
src/
└── Game.sol
```

## Compatibilities

Blockchains:
- Any EVM-compatible chain (e.g., Ethereum Mainnet, Sepolia, Arbitrum, Avalanche, Polygon)
Tokens:
- ETH (native currency of the blockchain)

[//]: # (scope-close)


[//]: # (getting-started-open)

## Setup

First, clone the project repository and install dependencies.

```bash
git clone https://github.com/CodeHawks-Contests/2025-07-last-man-standing.git
cd 2025-07-last-man-standing
forge install OpenZeppelin/openzeppelin-contracts
forge install foundry-rs/forge-std
forge build
```

[//]: # (getting-started-close)

[//]: # (known-issues-open)

None reported!

[//]: # (known-issues-close)
