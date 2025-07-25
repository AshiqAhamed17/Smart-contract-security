# Aderyn Analysis Report

This report was generated by [Aderyn](https://github.com/Cyfrin/aderyn), a static analysis tool built by [Cyfrin](https://cyfrin.io), a blockchain security company. This report is not a substitute for manual audit or security review. It should not be relied upon for any purpose other than to assist in the identification of potential security vulnerabilities.
# Table of Contents

- [Summary](#summary)
  - [Files Summary](#files-summary)
  - [Files Details](#files-details)
  - [Issue Summary](#issue-summary)
- [Low Issues](#low-issues)
  - [L-1: `public` functions not used internally could be marked `external`](#l-1-public-functions-not-used-internally-could-be-marked-external)
  - [L-2: Empty `require()` / `revert()` statements](#l-2-empty-require--revert-statements)
  - [L-3: Modifiers invoked only once can be shoe-horned into the function](#l-3-modifiers-invoked-only-once-can-be-shoe-horned-into-the-function)
  - [L-4: Empty Block](#l-4-empty-block)
  - [L-5: Unused Custom Error](#l-5-unused-custom-error)
  - [L-6: Potentially unused `private` / `internal` state variables found.](#l-6-potentially-unused-private--internal-state-variables-found)
  - [L-7: Boolean equality is not required.](#l-7-boolean-equality-is-not-required)
  - [L-8: Costly operations inside loops.](#l-8-costly-operations-inside-loops)
  - [L-9: State variable changes but no event is emitted.](#l-9-state-variable-changes-but-no-event-is-emitted)


# Summary

## Files Summary

| Key | Value |
| --- | --- |
| .sol Files | 2 |
| Total nSLOC | 243 |


## Files Details

| Filepath | nSLOC |
| --- | --- |
| src/LevelOne.sol | 203 |
| src/LevelTwo.sol | 40 |
| **Total** | **243** |


## Issue Summary

| Category | No. of Issues |
| --- | --- |
| High | 0 |
| Low | 9 |


# Low Issues

## L-1: `public` functions not used internally could be marked `external`

Instead of marking a function as `public`, consider marking it as `external` if it is not used internally.

<details><summary>8 Found Instances</summary>


- Found in src/LevelOne.sol [Line: 121](src/LevelOne.sol#L121)

	```solidity
	    function initialize(address _principal, uint256 _schoolFees, address _usdcAddress) public initializer {
	```

- Found in src/LevelOne.sol [Line: 204](src/LevelOne.sol#L204)

	```solidity
	    function addTeacher(address _teacher) public onlyPrincipal notYetInSession {
	```

- Found in src/LevelOne.sol [Line: 223](src/LevelOne.sol#L223)

	```solidity
	    function removeTeacher(address _teacher) public onlyPrincipal {
	```

- Found in src/LevelOne.sol [Line: 247](src/LevelOne.sol#L247)

	```solidity
	    function expel(address _student) public onlyPrincipal {
	```

- Found in src/LevelOne.sol [Line: 274](src/LevelOne.sol#L274)

	```solidity
	    function startSession(uint256 _cutOffScore) public onlyPrincipal notYetInSession {
	```

- Found in src/LevelOne.sol [Line: 282](src/LevelOne.sol#L282)

	```solidity
	    function giveReview(address _student, bool review) public onlyTeacher {
	```

- Found in src/LevelOne.sol [Line: 302](src/LevelOne.sol#L302)

	```solidity
	    function graduateAndUpgrade(address _levelTwo, bytes memory) public onlyPrincipal {
	```

- Found in src/LevelTwo.sol [Line: 28](src/LevelTwo.sol#L28)

	```solidity
	    function graduate() public reinitializer(2) {}
	```

</details>



## L-2: Empty `require()` / `revert()` statements

Use descriptive reason strings or custom errors for revert paths.

<details><summary>1 Found Instances</summary>


- Found in src/LevelOne.sol [Line: 249](src/LevelOne.sol#L249)

	```solidity
	            revert();
	```

</details>



## L-3: Modifiers invoked only once can be shoe-horned into the function



<details><summary>1 Found Instances</summary>


- Found in src/LevelOne.sol [Line: 101](src/LevelOne.sol#L101)

	```solidity
	    modifier onlyTeacher() {
	```

</details>



## L-4: Empty Block

Consider removing empty blocks.

<details><summary>2 Found Instances</summary>


- Found in src/LevelOne.sol [Line: 321](src/LevelOne.sol#L321)

	```solidity
	    function _authorizeUpgrade(address newImplementation) internal override onlyPrincipal {}
	```

- Found in src/LevelTwo.sol [Line: 28](src/LevelTwo.sol#L28)

	```solidity
	    function graduate() public reinitializer(2) {}
	```

</details>



## L-5: Unused Custom Error

it is recommended that the definition be removed when custom error is unused

<details><summary>1 Found Instances</summary>


- Found in src/LevelOne.sol [Line: 86](src/LevelOne.sol#L86)

	```solidity
	    error HH__HawkHighFeesNotPaid();
	```

</details>



## L-6: Potentially unused `private` / `internal` state variables found.

State variable appears to be unused. No analysis has been performed to see if any inilne assembly references it. So if that's not the case, consider removing this unused variable.

<details><summary>1 Found Instances</summary>


- Found in src/LevelTwo.sol [Line: 12](src/LevelTwo.sol#L12)

	```solidity
	    bool inSession;
	```

</details>



## L-7: Boolean equality is not required.

If `x` is a boolean, there is no need to do `if(x == true)` or `if(x == false)`. Just use `if(x)` and `if(!x)` respectively.

<details><summary>2 Found Instances</summary>


- Found in src/LevelOne.sol [Line: 109](src/LevelOne.sol#L109)

	```solidity
	        if (inSession == true) {
	```

- Found in src/LevelOne.sol [Line: 248](src/LevelOne.sol#L248)

	```solidity
	        if (inSession == false) {
	```

</details>



## L-8: Costly operations inside loops.

Invoking `SSTORE`operations in loops may lead to Out-of-gas errors. Use a local variable to hold the loop computation result.

<details><summary>2 Found Instances</summary>


- Found in src/LevelOne.sol [Line: 234](src/LevelOne.sol#L234)

	```solidity
	        for (uint256 n = 0; n < teacherLength; n++) {
	```

- Found in src/LevelOne.sol [Line: 261](src/LevelOne.sol#L261)

	```solidity
	        for (uint256 n = 0; n < studentLength; n++) {
	```

</details>



## L-9: State variable changes but no event is emitted.

State variable changes in this function but no event is emitted.

<details><summary>1 Found Instances</summary>


- Found in src/LevelOne.sol [Line: 121](src/LevelOne.sol#L121)

	```solidity
	    function initialize(address _principal, uint256 _schoolFees, address _usdcAddress) public initializer {
	```

</details>



