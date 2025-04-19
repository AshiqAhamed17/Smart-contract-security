# [M-1] Unchecked Return Value of transferFrom May Lead to Undetected Token Transfer Failures

## Summary

A transferFrom call is made to an ERC20 token contract without verifying its return value. This can lead to unexpected behavior if the transfer fails silently (i.e., returns false but does not revert).&#x20;

## Vulnerability Details

ERC20’s transferFrom() function is defined to return a bool indicating success. Some non-standard or outdated tokens may return false rather than reverting on failure.

In both of these functions i.e 
`RockPaperScissors::createGameWithToken` and `RockPaperScissors::joinGameWithToken`have the same issue

```Solidity
// Transfer token to contract
winningToken.transferFrom(msg.sender, address(this), 1);
```

#
3 Impact

**Medium.**

* Failing to check the result may cause logic to proceed as if a token was transferred, when in fact it was not.
* This is particularly risky when interacting with **non-compliant ERC20 tokens**, or tokens like USDT that do not revert on failure.

## Tools Used

* Manual Review
* Slither
* OpenZeppelin ERC20 standard documentation

## Recommendations

* Use OpenZeppelin’s SafeERC20 wrapper which handles non-reverting tokens safely:

```diff
    pragma solidity ^0.8.13;

   import "./WinningToken.sol";
+  import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
+  using SafeERC20 for IERC20;
   .
   .
   .

   function createGameWithToken(uint256 _totalTurns, uint256 _timeoutInterval) external returns (uint256) {

-     winningToken.transferFrom(msg.sender, address(this), 1)
+     winningToken.safeTransferFrom(msg.sender, address(this), 1);

```

•	Alternatively, explicitly check the return value:

```solidity
  require(winningToken.transferFrom(msg.sender, address(this), 1), "Transfer failed");
```



# [#L-1] Centralization Risk Due to Owner Privileges in WinningToken

## Summary

The `RockPaperScissors::WinningToken` contract uses the Ownable pattern, granting a single address full control over minting tokens. This introduces a centralization risk where a privileged owner can arbitrarily mint new tokens, potentially undermining fairness and trust in the reward system.

## Vulnerability Details

The contract inherits from OpenZeppelin’s Ownable, and includes a mint() function restricted to the owner:

```javascript
contract WinningToken is ERC20, ERC20Burnable, Ownable {
```

```JavaScript
function mint(address to, uint256 amount) external onlyOwner {
    _mint(to, amount);
}
```

## Impact

Low

## Tools Used

* Manual Review
* Context analysis from README.md

## Recommendations

* Restrict minting access to **game logic contracts** (e.g., RockPaperScissors) instead of a single owner.
* Use **AccessControl** or **minter roles** instead of Ownable.


---


# [#L-2]Unused public Functions Can Be Marked external

## Summary

Several functions in the codebase are marked as public but are never called internally. In such cases, the external visibility specifier is more appropriate, as it reduces gas costs slightly when the function is called externally.

## Vulnerability Details

In Solidity, public functions can be accessed both internally and externally, while external functions can only be called from outside the contract. If a function is not used internally, using external is a gas optimization.

Found Instances:

```solidity
function tokenOwner() public view returns (address) {
```

```solidity
function decimals() public view virtual override returns (uint8) {
```

•	tokenOwner() is not called anywhere within the contract, so it can be safely marked external.

•	decimals() is overriding the base ERC20 contract and needs to stay public for compatibility with ERC20 interfaces, so this instance is not actionable and can be ignored.

## Impact

**Low.**

&#x20;

Changing public to external can result in minor gas savings when the function is called externally. It also improves clarity by enforcing intended usage boundaries.

## Tools Used

* Manual Review
* Solidity Compiler Warnings

## Recommendations

```diff
-     function tokenOwner() public view returns (address) {
+     function tokenOwner() external view returns (address) {

```

