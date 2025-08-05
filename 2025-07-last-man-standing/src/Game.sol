// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Game is Ownable {

    // --- State Variables ---

    // Game Core State
    address public currentKing; // The address of the current "King"
    uint256 public lastClaimTime; // Timestamp when the throne was last claimed
    uint256 public gracePeriod; // Time in seconds after which a winner can be declared (e.g., 24 hours)
    uint256 public pot; // Total ETH accumulated for the winner
    uint256 public claimFee; // Current ETH fee required to claim the throne
    bool public gameEnded; // True if a winner has been declared for the current round

    // Game Parameters (Configurable by Owner)
    uint256 public initialClaimFee; // The starting fee for a new game round
    uint256 public feeIncreasePercentage; // Percentage by which the claimFee increases after each successful claim (e.g., 10 for 10%)
    uint256 public platformFeePercentage; // Percentage of the claimFee that goes to the contract owner (deployer)
    uint256 public initialGracePeriod; // The grace period set at the start of a new game round

    // Payouts and Balances
    mapping(address => uint256) public pendingWinnings; // Stores ETH owed to the declared winner (pot + prev king payouts)
    uint256 public platformFeesBalance; // Accumulated platform fees for the contract owner

    // Game Analytics/History
    uint256 public gameRound; // Current round number of the game
    uint256 public totalClaims; // Total number of throne claims across all rounds
    mapping(address => uint256) public playerClaimCount; // How many times an address has claimed the throne in total

    // Manual Reentrancy Guard
    bool private _locked; // Flag to prevent reentrant calls

    // --- Events ---

    /**
     * @dev Emitted when a new player successfully claims the throne.
     * @param newKing The address of the new king.
     * @param claimAmount The ETH amount sent by the new king.
     * @param newClaimFee The updated claim fee for the next claim.
     * @param newPot The updated total pot for the winner.
     * @param timestamp The block timestamp when the claim occurred.
     */
    event ThroneClaimed(
        address indexed newKing,
        uint256 claimAmount,
        uint256 newClaimFee,
        uint256 newPot,
        uint256 timestamp
    );

    /**
     * @dev Emitted when the game ends and a winner is declared.
     * @param winner The address of the declared winner.
     * @param prizeAmount The total prize amount won.
     * @param timestamp The block timestamp when the winner was declared.
     * @param round The game round that just ended.
     */
    event GameEnded(
        address indexed winner,
        uint256 prizeAmount,
        uint256 timestamp,
        uint256 round
    );

    /**
     * @dev Emitted when a winner successfully withdraws their prize.
     * @param to The address that withdrew the winnings.
     * @param amount The amount of ETH withdrawn.
     */
    event WinningsWithdrawn(address indexed to, uint256 amount);

    /**
     * @dev Emitted when the contract owner withdraws accumulated platform fees.
     * @param to The address that withdrew the fees (owner).
     * @param amount The amount of ETH withdrawn.
     */
    event PlatformFeesWithdrawn(address indexed to, uint256 amount);

    /**
     * @dev Emitted when a new game round is started.
     * @param newRound The number of the new game round.
     * @param timestamp The block timestamp when the game was reset.
     */
    event GameReset(uint256 newRound, uint256 timestamp);

    /**
     * @dev Emitted when the grace period is updated by the owner.
     * @param newGracePeriod The new grace period in seconds.
     */
    event GracePeriodUpdated(uint256 newGracePeriod);

    /**
     * @dev Emitted when the claim fee parameters are updated by the owner.
     * @param newInitialClaimFee The new initial claim fee.
     * @param newFeeIncreasePercentage The new fee increase percentage.
     */
    event ClaimFeeParametersUpdated(
        uint256 newInitialClaimFee,
        uint256 newFeeIncreasePercentage
    );

    /**
     * @dev Emitted when the platform fee percentage is updated by the owner.
     * @param newPlatformFeePercentage The new platform fee percentage.
     */
    event PlatformFeePercentageUpdated(uint256 newPlatformFeePercentage);

    // --- Modifiers ---

    /**
     * @dev Throws if the game has already ended.
     */
    modifier gameNotEnded() {
        require(!gameEnded, "Game: Game has already ended. Reset to play again.");
        _;
    }

    /**
     * @dev Throws if the game has not yet ended.
     */
    modifier gameEndedOnly() {
        require(gameEnded, "Game: Game has not ended yet.");
        _;
    }

    /**
     * @dev Throws if the provided percentage is not between 0 and 100 (inclusive).
     * @param _percentage The percentage value to validate.
     */
    modifier isValidPercentage(uint256 _percentage) {
        require(_percentage <= 100, "Game: Percentage must be 0-100.");
        _;
    }

    /**
     * @dev Prevents reentrant calls to a function.
     * This is a manual implementation of a reentrancy guard.
     */
    modifier nonReentrant() {
        require(!_locked, "ReentrancyGuard: reentrant call");
        _locked = true;
        _;
        _locked = false;
    }

    /**
     * @dev Initializes the game contract.
     * @param _initialClaimFee The starting fee to claim the throne.
     * @param _gracePeriod The initial grace period in seconds (e.g., 86400 for 24 hours).
     * @param _feeIncreasePercentage The percentage increase for the claim fee (0-100).
     * @param _platformFeePercentage The percentage of claim fee for the owner (0-100).
     */
    constructor(
        uint256 _initialClaimFee,
        uint256 _gracePeriod,
        uint256 _feeIncreasePercentage,
        uint256 _platformFeePercentage
    ) Ownable(msg.sender) { // Set deployer as owner
        require(_initialClaimFee > 0, "Game: Initial claim fee must be greater than zero.");
        require(_gracePeriod > 0, "Game: Grace period must be greater than zero.");
        require(_feeIncreasePercentage <= 100, "Game: Fee increase percentage must be 0-100.");
        require(_platformFeePercentage <= 100, "Game: Platform fee percentage must be 0-100.");

        initialClaimFee = _initialClaimFee;
        initialGracePeriod = _gracePeriod;
        feeIncreasePercentage = _feeIncreasePercentage;
        platformFeePercentage = _platformFeePercentage;

        // Initialize game state for the first round
        claimFee = initialClaimFee;
        gracePeriod = initialGracePeriod;
        lastClaimTime = block.timestamp; // Game starts immediately upon deployment
        gameRound = 1;
        gameEnded = false;
        // currentKing starts as address(0) until first claim
    }

    /**
     * @dev Allows a player to claim the throne by sending the required claim fee.
     * If there's a previous king, a small portion of the new claim fee is sent to them.
     * A portion also goes to the platform owner, and the rest adds to the pot.
     */
    function claimThrone() external payable gameNotEnded nonReentrant {
        require(msg.value >= claimFee, "Game: Insufficient ETH sent to claim the throne.");
        require(msg.sender != currentKing, "Game: You are already the king. No need to re-claim.");

        uint256 sentAmount = msg.value;
        uint256 previousKingPayout = 0;
        uint256 currentPlatformFee = 0;
        uint256 amountToPot = 0;

        // Calculate platform fee
        currentPlatformFee = (sentAmount * platformFeePercentage) / 100;

        // Defensive check to ensure platformFee doesn't exceed available amount after previousKingPayout
        if (currentPlatformFee > (sentAmount - previousKingPayout)) {
            currentPlatformFee = sentAmount - previousKingPayout;
        }
        platformFeesBalance = platformFeesBalance + currentPlatformFee;

        // Remaining amount goes to the pot
        amountToPot = sentAmount - currentPlatformFee;
        pot = pot + amountToPot;

        // Update game state
        currentKing = msg.sender;
        lastClaimTime = block.timestamp;
        playerClaimCount[msg.sender] = playerClaimCount[msg.sender] + 1;
        totalClaims = totalClaims + 1;

        // Increase the claim fee for the next player
        claimFee = claimFee + (claimFee * feeIncreasePercentage) / 100;

        emit ThroneClaimed(
            msg.sender,
            sentAmount,
            claimFee,
            pot,
            block.timestamp
        );
    }

    /**
     * @dev Allows anyone to declare a winner if the grace period has expired.
     * The currentKing at the time the grace period expires becomes the winner.
     * The pot is then made available for the winner to withdraw.
     */
    function declareWinner() external gameNotEnded {
        require(currentKing != address(0), "Game: No one has claimed the throne yet.");
        require(
            block.timestamp > lastClaimTime + gracePeriod,
            "Game: Grace period has not expired yet."
        );

        gameEnded = true;

        pendingWinnings[currentKing] = pendingWinnings[currentKing] + pot;
        pot = 0; // Reset pot after assigning to winner's pending winnings

        emit GameEnded(currentKing, pot, block.timestamp, gameRound);
    }

    /**
     * @dev Allows the declared winner to withdraw their prize.
     * Uses a secure withdraw pattern with a manual reentrancy guard.
     */
    function withdrawWinnings() external nonReentrant {
        uint256 amount = pendingWinnings[msg.sender];
        require(amount > 0, "Game: No winnings to withdraw.");

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Game: Failed to withdraw winnings.");

        pendingWinnings[msg.sender] = 0;

        emit WinningsWithdrawn(msg.sender, amount);
    }

    /**
     * @dev Allows the contract owner to reset the game for a new round.
     * Can only be called after a winner has been declared.
     */
    function resetGame() external onlyOwner gameEndedOnly {
        currentKing = address(0);
        lastClaimTime = block.timestamp;
        pot = 0;
        claimFee = initialClaimFee;
        gracePeriod = initialGracePeriod;
        gameEnded = false;
        gameRound = gameRound + 1;
        // totalClaims is cumulative across rounds, not reset here, but could be if desired.

        emit GameReset(gameRound, block.timestamp);
    }

    /**
     * @dev Allows the contract owner to update the grace period.
     * @param _newGracePeriod The new grace period in seconds.
     */
    function updateGracePeriod(uint256 _newGracePeriod) external onlyOwner {
        require(_newGracePeriod > 0, "Game: New grace period must be greater than zero.");
        gracePeriod = _newGracePeriod;
        emit GracePeriodUpdated(_newGracePeriod);
    }

    /**
     * @dev Allows the contract owner to update the initial claim fee and fee increase percentage.
     * @param _newInitialClaimFee The new initial claim fee.
     * @param _newFeeIncreasePercentage The new fee increase percentage (0-100).
     */
    function updateClaimFeeParameters(
        uint256 _newInitialClaimFee,
        uint256 _newFeeIncreasePercentage
    ) external onlyOwner isValidPercentage(_newFeeIncreasePercentage) {
        require(_newInitialClaimFee > 0, "Game: New initial claim fee must be greater than zero.");
        initialClaimFee = _newInitialClaimFee;
        feeIncreasePercentage = _newFeeIncreasePercentage;
        emit ClaimFeeParametersUpdated(_newInitialClaimFee, _newFeeIncreasePercentage);
    }

    /**
     * @dev Allows the contract owner to update the platform fee percentage.
     * @param _newPlatformFeePercentage The new platform fee percentage (0-100).
     */
    function updatePlatformFeePercentage(uint256 _newPlatformFeePercentage)
        external
        onlyOwner
        isValidPercentage(_newPlatformFeePercentage)
    {
        platformFeePercentage = _newPlatformFeePercentage;
        emit PlatformFeePercentageUpdated(_newPlatformFeePercentage);
    }

    /**
     * @dev Allows the contract owner to withdraw accumulated platform fees.
     * Uses a secure withdraw pattern with a manual reentrancy guard.
     */
    function withdrawPlatformFees() external onlyOwner nonReentrant {
        uint256 amount = platformFeesBalance;
        require(amount > 0, "Game: No platform fees to withdraw.");

        platformFeesBalance = 0;

        (bool success, ) = payable(owner()).call{value: amount}("");
        require(success, "Game: Failed to withdraw platform fees.");

        emit PlatformFeesWithdrawn(owner(), amount);
    }

    /**
     * @dev Returns the time remaining until the grace period expires and a winner can be declared.
     * Returns 0 if the grace period has already expired or the game has ended.
     */
    function getRemainingTime() public view returns (uint256) {
        if (gameEnded) {
            return 0; // Game has ended, no remaining time
        }
        uint256 endTime = lastClaimTime + gracePeriod;
        if (block.timestamp >= endTime) {
            return 0; // Grace period has expired
        }
        return endTime - block.timestamp;
    }

    /**
     * @dev Returns the current balance of the contract (should match the pot plus platform fees unless payouts are pending).
     */
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    receive() external payable {}
}