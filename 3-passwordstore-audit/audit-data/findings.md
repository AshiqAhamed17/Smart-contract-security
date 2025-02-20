## [S-#] Storing the password on-chain makes it visible to anyone, and no longer private.

### Description:
All data stored on-chain is visible to anyone, and can be read directly from the blockchain. The `PasswordStore::s_password` is intended to be a private variable and can be only accessed through the `PasswordStore:: getPassword` function, which is intended to only called by the owner of the contract.

We show one such method of reading data off-chain below

### Impact:

Anyone can read the private password, severly breaking the functionality of the protocol.

### Proof of Concept:

(Proof of Code)

The below test case shows how anyone can read the password directly from the blockchain.

1. Create a locally running chain

```bash
make anvil
```

2. Deploy the contract to the chain

```
make deploy
```

3.Run the local tool

```
cast storage <YOUR_ADDRESS> 1 --rpc-url 127.0.0.1:8545
0x6d7950617373776f726400000000000000000000000000000000000000000014
```

`1` is the storage slot fo the `PasswordStore::s_password` variable and `0x6d7950617373776f726400000000000000000000000000000000000000000014` is the password in bytes32

You can then parse the bytes32 into a string by:

```
cast parse-bytes32-string 0x6d7950617373776f726400000000000000000000000000000000000000000014
```

And get an output of
`myPassword`

### Recommended Mitigation:
Due to this the overall contract has to be rethought.

---
---

## [S-#] The `PasswordStore::setPassword` has no access control, meaning anyone can change the password.

### Description:
The `PasswordStore::setPassword` function can only be called by the owner as per the natspec
` * @notice This function allows only the owner to set a new password`
, but as the function is external and there is no access control non-owners can also call this function.

```javascript
function setPassword(string memory newPassword) external onlyOwner {
->  //@audit - There is no access control
    s_password = newPassword;
    emit SetNetPassword();
}
```
 
### Impact:
Anyone can set/update the password of the contract, severly breaking the contract intended functionality

### Proof of Concept:

### Recommended Mitigation:


