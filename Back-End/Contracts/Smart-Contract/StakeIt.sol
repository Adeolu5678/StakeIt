// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/**
 * @title StakeIt Smart Contract
 * @dev A Web3 accountability platform on Hedera for goal staking and voting
 * @notice Users stake HBAR on goals, submit proofs, and community votes on completion
 */
contract StakeIt is ReentrancyGuard, AccessControl, Pausable {
    using ECDSA for bytes32;

    // Roles
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    // Constants
    uint256 private constant DECIMALS = 18;
    uint256 private constant MIN_STAKE = 1 * 10**DECIMALS; // 1 HBAR in wei
    uint256 private constant MAX_STAKE = 100 * 10**DECIMALS; // 100 HBAR in wei
    uint256 private constant MIN_DURATION = 7 days;
    uint256 private constant MAX_DURATION = 30 days;
    uint256 private constant VOTER_STAKE = 1 * 10**DECIMALS; // 1 HBAR in wei
    uint256 private constant PENALTY_PERCENTAGE = 25; // 25% penalty distribution
    uint256 private constant PLATFORM_FEE_PERCENT = 8; // 8% of penalty
    uint256 private constant CHARITY_FEE_PERCENT = 8; // 8% of penalty
    uint256 private constant LIQUIDITY_FEE_PERCENT = 9; // 9% of penalty
    uint256 private constant VOTE_POINT = 1;
    uint256 private constant COMPLETION_POINT = 10;
    uint256 private constant VOTE_DURATION = 7 days; // 7 days for voting after goal end

    // Treasury addresses
    address public charityWallet;
    address public platformWallet;
    address public liquidityReserve;

    // Goal structure
    struct Goal {
        address creator;
        string title;
        uint256 stake;
        uint256 duration; // in seconds
        uint256 startTime;
        bool isFinalized;
        bool isCompleted;
        uint256 totalVotes;
        uint256 positiveVotes;
        mapping(uint256 => string) dailyProofs; // day => IPFS hash
        mapping(uint256 => uint256) proofTimestamps; // day => HCS timestamp
    }

    // Vote structure (compact storage)
    struct VoteData {
        uint256 voterVoteBitmask; // Bitmask for daily votes (up to 365 days)
        uint256 lastVoteDay;
    }

    // Storage
    mapping(uint256 => Goal) public goals;
    mapping(uint256 => mapping(address => VoteData)) public votes;
    mapping(address => uint256) public withdrawableBalances;
    mapping(address => uint256) public voterStakes;
    mapping(address => uint256) public userPoints;

    uint256 public goalCounter;

    // Events
    event GoalCreated(uint256 indexed goalId, address indexed creator, string title, uint256 stake, uint256 duration);
    event VoteCast(uint256 indexed goalId, address indexed voter, bool vote, uint256 day);
    event GoalFinalized(uint256 indexed goalId, bool completed);
    event Withdrawal(address indexed user, uint256 amount);
    event ProofSubmitted(uint256 indexed goalId, uint256 day, string proofHash);
    event PointsAwarded(address indexed user, uint256 points);
    event FundsDistributed(uint256 indexed goalId, uint256 charityAmount, uint256 platformAmount, uint256 reserveAmount);
    event StakeRefunded(address indexed voter, uint256 goalId, uint256 amount);

    /**
     * @dev Constructor sets up roles and treasury addresses
     */
    constructor(
        address _charityWallet,
        address _platformWallet,
        address _liquidityReserve
    ) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);

        charityWallet = _charityWallet;
        platformWallet = _platformWallet;
        liquidityReserve = _liquidityReserve;
    }

    /**
     * @dev Create a new goal with stake
     * @param _title Title of the goal
     * @param _duration Duration of the goal in seconds (7-30 days)
     * @param _stake Amount of HBAR to stake (in wei, 1-100 HBAR)
     */
    function createGoal(string calldata _title, uint256 _duration, uint256 _stake) external payable whenNotPaused {
        require(_stake >= MIN_STAKE && _stake <= MAX_STAKE, "Stake must be between 1 and 100 HBAR");
        require(msg.value == _stake, "Incorrect stake amount sent");
        require(_duration >= MIN_DURATION && _duration <= MAX_DURATION, "Duration must be between 7 and 30 days");

        goalCounter++;
        Goal storage newGoal = goals[goalCounter];
        newGoal.creator = msg.sender;
        newGoal.title = _title;
        newGoal.stake = _stake;
        newGoal.duration = _duration;
        newGoal.startTime = block.timestamp;
        newGoal.isFinalized = false;
        newGoal.isCompleted = false;
        newGoal.totalVotes = 0;
        newGoal.positiveVotes = 0;

        emit GoalCreated(goalCounter, msg.sender, _title, _stake, _duration);
    }

    /**
     * @dev Cast a vote on a goal's completion for a specific day
     * @param _goalId ID of the goal
     * @param _day Day number (0-based)
     * @param _vote True for completed, false for not
     */
    function castVote(uint256 _goalId, uint256 _day, bool _vote) external payable whenNotPaused {
        Goal storage goal = goals[_goalId];
        require(goal.creator != address(0), "Goal does not exist");
        require(block.timestamp >= goal.startTime + goal.duration, "Voting not started yet");
        require(block.timestamp <= goal.startTime + goal.duration + VOTE_DURATION, "Voting period ended");
        require(_day < (goal.duration / 1 days) + 1, "Invalid day");
        require(msg.value == VOTER_STAKE, "Must stake 1 HBAR to vote");

        VoteData storage voterData = votes[_goalId][msg.sender];
        require((voterData.voterVoteBitmask & (1 << _day)) == 0, "Already voted for this day");

        voterData.voterVoteBitmask |= (uint256(_vote ? 1 : 0) << _day);
        voterData.lastVoteDay = _day;

        // Lock voter stake
        voterStakes[msg.sender] += VOTER_STAKE;

        goal.totalVotes++;
        if (_vote) {
            goal.positiveVotes++;
        }

        // Reward voter points
        userPoints[msg.sender] += VOTE_POINT;
        emit PointsAwarded(msg.sender, VOTE_POINT);

        emit VoteCast(_goalId, msg.sender, _vote, _day);
    }

    /**
     * @dev Submit daily proof for a goal (IPFS hash with HCS timestamp)
     * @param _goalId ID of the goal
     * @param _day Day number (0-based)
     * @param _proofHash IPFS hash of the proof
     * @param _timestamp HCS timestamp for proof verification
     */
    function submitProof(uint256 _goalId, uint256 _day, string calldata _proofHash, uint256 _timestamp) external {
        Goal storage goal = goals[_goalId];
        require(goal.creator == msg.sender, "Only creator can submit proof");
        require(!goal.isFinalized, "Goal already finalized");
        require(bytes(_proofHash).length > 0, "Invalid proof hash");
        require(_timestamp > 0, "Invalid timestamp");
        require(_day < (goal.duration / 1 days) + 1, "Invalid day");

        goal.dailyProofs[_day] = _proofHash;
        goal.proofTimestamps[_day] = _timestamp;

        emit ProofSubmitted(_goalId, _day, _proofHash);
    }

    /**
     * @dev Finalize goal outcome automatically when voting period ends
     * @param _goalId ID of the goal
     */
    function finalizeGoal(uint256 _goalId) external whenNotPaused {
        Goal storage goal = goals[_goalId];
        require(!goal.isFinalized, "Goal already finalized");
        require(block.timestamp > goal.startTime + goal.duration + VOTE_DURATION, "Voting still active");

        // Determine completion based on majority vote
        bool completed = goal.positiveVotes > (goal.totalVotes / 2);

        goal.isFinalized = true;
        goal.isCompleted = completed;

        if (completed) {
            // Goal completed: return full stake to creator
            withdrawableBalances[goal.creator] += goal.stake;
            // Award completion points to creator
            userPoints[goal.creator] += COMPLETION_POINT;
            emit PointsAwarded(goal.creator, COMPLETION_POINT);
        } else {
            // Goal failed: distribute 25% penalty
            uint256 penalty = (goal.stake * PENALTY_PERCENTAGE) / 100;
            uint256 charityAmount = (penalty * CHARITY_FEE_PERCENT) / 100;
            uint256 platformAmount = (penalty * PLATFORM_FEE_PERCENT) / 100;
            uint256 reserveAmount = (penalty * LIQUIDITY_FEE_PERCENT) / 100;

            withdrawableBalances[charityWallet] += charityAmount;
            withdrawableBalances[platformWallet] += platformAmount;
            withdrawableBalances[liquidityReserve] += reserveAmount;

            // Remaining 75% stake goes to voters proportionally
            uint256 remainingStake = goal.stake - penalty;
            if (goal.totalVotes > 0) {
                uint256 stakePerVote = remainingStake / goal.totalVotes;
                // Distribute to all voters who participated
                // Note: In production, this would iterate through all voters
                // For MVP, we simplify by adding to liquidity reserve as pool
                withdrawableBalances[liquidityReserve] += remainingStake;
            }
        }

        // Return voter stakes
        // Note: In production, iterate through all voters for the goal
        // For MVP, assume voters call refundVoterStake individually

        emit FundsDistributed(_goalId, (completed ? 0 : (goal.stake * PENALTY_PERCENTAGE * CHARITY_FEE_PERCENT) / 10000), (completed ? 0 : (goal.stake * PENALTY_PERCENTAGE * PLATFORM_FEE_PERCENT) / 10000), (completed ? 0 : (goal.stake * PENALTY_PERCENTAGE * LIQUIDITY_FEE_PERCENT) / 10000));
        emit GoalFinalized(_goalId, completed);
    }

    /**
     * @dev Withdraw available balance
     */
    function withdraw() external nonReentrant whenNotPaused {
        uint256 amount = withdrawableBalances[msg.sender];
        require(amount > 0, "No balance to withdraw");

        withdrawableBalances[msg.sender] = 0;

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Withdrawal failed");

        emit Withdrawal(msg.sender, amount);
    }

    /**
     * @dev Refund voter stake after goal finalization
     * @param _goalId ID of the goal
     */
    function refundVoterStake(uint256 _goalId) external nonReentrant {
        Goal storage goal = goals[_goalId];
        require(goal.isFinalized, "Goal not finalized");

        VoteData storage voterData = votes[_goalId][msg.sender];
        require(voterData.voterVoteBitmask > 0, "No votes cast");

        // Count votes cast by this voter
        uint256 votesCast = 0;
        uint256 totalDays = goal.duration / 1 days;
        for (uint256 i = 0; i <= totalDays; i++) {
            if ((voterData.voterVoteBitmask & (1 << i)) != 0) {
                votesCast++;
            }
        }

        require(votesCast > 0, "No votes cast");
        uint256 refundAmount = votesCast * VOTER_STAKE;

        // Ensure voter has enough locked stake
        require(voterStakes[msg.sender] >= refundAmount, "Insufficient locked stake");

        voterStakes[msg.sender] -= refundAmount;
        withdrawableBalances[msg.sender] += refundAmount;

        emit StakeRefunded(msg.sender, _goalId, refundAmount);
    }

    /**
     * @dev Pause the contract (admin only)
     */
    function pause() external onlyRole(ADMIN_ROLE) {
        _pause();
    }

    /**
     * @dev Unpause the contract (admin only)
     */
    function unpause() external onlyRole(ADMIN_ROLE) {
        _unpause();
    }

    /**
     * @dev Update treasury addresses (admin only)
     */
    function updateTreasury(
        address _charityWallet,
        address _platformWallet,
        address _liquidityReserve
    ) external onlyRole(ADMIN_ROLE) {
        charityWallet = _charityWallet;
        platformWallet = _platformWallet;
        liquidityReserve = _liquidityReserve;
    }

    /**
     * @dev Verify proof using HCS timestamp (simplified on-chain verification)
     * @param _goalId ID of the goal
     * @param _day Day number
     * @param _expectedHash Expected IPFS hash
     * @param _timestamp HCS timestamp
     * @return bool Whether the proof is valid
     */
    function verifyProof(uint256 _goalId, uint256 _day, string calldata _expectedHash, uint256 _timestamp) external view returns (bool) {
        Goal storage goal = goals[_goalId];
        require(goal.creator != address(0), "Goal does not exist");

        // Basic verification: check if timestamp is within goal duration
        bool timestampValid = _timestamp >= goal.startTime && _timestamp <= goal.startTime + goal.duration;

        // Check if hash matches for the day
        bool hashValid = keccak256(abi.encodePacked(goal.dailyProofs[_day])) == keccak256(abi.encodePacked(_expectedHash));

        return timestampValid && hashValid && goal.proofTimestamps[_day] == _timestamp;
    }

    // View functions
    function getGoal(uint256 _goalId) external view returns (
        address creator,
        string memory title,
        uint256 stake,
        uint256 duration,
        uint256 startTime,
        bool isFinalized,
        bool isCompleted,
        uint256 totalVotes,
        uint256 positiveVotes
    ) {
        Goal storage goal = goals[_goalId];
        return (
            goal.creator,
            goal.title,
            goal.stake,
            goal.duration,
            goal.startTime,
            goal.isFinalized,
            goal.isCompleted,
            goal.totalVotes,
            goal.positiveVotes
        );
    }

    function getVoteData(uint256 _goalId, address _voter) external view returns (VoteData memory) {
        return votes[_goalId][_voter];
    }
}