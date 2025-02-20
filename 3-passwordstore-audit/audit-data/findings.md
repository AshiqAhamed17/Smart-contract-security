### [S-#] Storing the password on-chain makes it visible to anyone, and no longer private.


**Description:**
All data stored on-chain is visible to anyone, and can be read directly from the blockchain. The `PasswordStore::s_password` is intended to be a private variable and can be only accessed through the `PasswordStore:: getPassword` function, which is intended to only called by the owner of the contract.

We show one such method of reading data off-chain below

**Impact:** Anyone can read the private password, severly breaking the functionality of the protocol.

**Proof of Concept:** (Proof of Code)

The below test case shows how anyone can read the password directly from the blockchain.

**Recommended Mitigation:** 