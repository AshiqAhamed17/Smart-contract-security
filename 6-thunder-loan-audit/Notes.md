
## ⚡️ThunderLoan⚡️ protocol
Give users a way to create flash loans
Give liquidity providers a way to earn money off their capital

## what is AAVE ?
- Borrowing and Lending protocol just like a bank.
- It's Overcollateralized - If you want to borrow $100 worth token A you'll need to give $120 worth
- Provides Flash Loans to users - Users can borrow any amount as only as they pay it back in the same transaction block.

## Terms
Liquidity Provider: Someone who deposits money into a protocol to earn interest.
- Where is the interest coming from ?
 - Uniswap(TSwap): Fees from swapping
 - AAVE(Thunder Loans): Fees from loans
    deposit -> ThunderLoan -> AssetTokens

## Flash Loans
- Users can borrow huge amount of assets and use for some other reasons like taking adv of arbitrage and gain profit. Users can borrow as long as they pay it back (with some % fee) within the same tx if not paid the tx will revert



### Deployable Logic Contracts:
**Total: 3**
- ThunderLoan
- AssetToken
- ThunderLoanUpgraded

*No of lines: 391*
