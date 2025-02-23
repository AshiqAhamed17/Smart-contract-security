## [M-#] Looping through the players array to check for duplicates in the `PuppyRaffle.sol::enterRaffle`is a potential denial of service (DoS) attack, incrementing gas cost for the future entrance.

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