// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./interfaces/IToken.sol";
import "./interfaces/ITGE.sol";
import "./interfaces/IService.sol";
import "./interfaces/IPool.sol";
import "./libraries/ExceptionsLibrary.sol";

/// @title Token Generation Event
contract TGE is Initializable, ReentrancyGuardUpgradeable, ITGE {
    using AddressUpgradeable for address payable;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // CONSTANTS

    /// @notice Denominator for shares (such as thresholds)
    uint256 private constant DENOM = 100 * 10**4;

    /// @dev Pool's ERC20 token
    IToken public token;

    /// @dev TGE info struct
    TGEInfo public info;

    /// @dev Mapping of user's address to whitelist status
    mapping(address => bool) private _isUserWhitelisted;

    /// @dev Block of TGE's creation
    uint256 public createdAt;

    /// @dev Mapping of an address to total amount of tokens purchased during TGE
    mapping(address => uint256) public purchaseOf;

    /// @dev Total amount of tokens purchased during TGE
    uint256 public totalPurchased;

    /// @dev Is vesting TVL reached. Users can claim their tokens only if vesting TVL was reached.
    bool public vestingTVLReached;

    /// @dev Is lockup TVL reached. Users can claim their tokens only if lockup TVL was reached.
    bool public lockupTVLReached;

    /// @dev Mapping of addresses to total amounts of tokens vested
    mapping(address => uint256) public vestedBalanceOf;

    /// @dev Total amount of tokens vested
    uint256 public totalVested;

    /// @dev Protocol fee
    uint256 public protocolFee;

    /// @dev Protocol token fee is a percentage of tokens sold during TGE. Returns true if fee was claimed by the governing DAO.
    bool public isProtocolTokenFeeClaimed;

    // EVENTS

    /**
     * @dev Event emitted on token purchase.
     * @param buyer buyer
     * @param amount amount of tokens
     */
    event Purchased(address buyer, uint256 amount);

    /**
     * @dev Event emitted on claim of protocol token fee.
     * @param token token
     * @param tokenFee amount of tokens
     */
    event ProtocolTokenFeeClaimed(address token, uint256 tokenFee);

    /**
     * @dev Event emitted on token claim.
     * @param account Redeemer address
     * @param refundValue Refund value
     */
    event Redeemed(address account, uint256 refundValue);

    /**
     * @dev Event emitted on token claim.
     * @param account Claimer address
     * @param amount Amount of claimed tokens
     */
    event Claimed(address account, uint256 amount);

    /**
     * @dev Event emitted on transfer funds to pool.
     * @param amount Amount of transferred tokens/ETH
     */
    event FundsTransferred(uint256 amount);

    // INITIALIZER AND CONSTRUCTOR

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Constructor function, can only be called once
     * @param _token pool's token
     * @param _info TGE parameters
     */
    function initialize(
        IToken _token,
        TGEInfo calldata _info,
        uint256 protocolFee_
    ) external initializer {
        __ReentrancyGuard_init();
        IService(msg.sender).validateTGEInfo(
            _info,
            _token.cap(),
            _token.totalSupply(),
            _token.tokenType()
        );

        token = _token;
        info = _info;
        protocolFee = protocolFee_;
        vestingTVLReached = (_info.vestingTVL == 0);
        lockupTVLReached = (_info.lockupTVL == 0);

        for (uint256 i = 0; i < _info.userWhitelist.length; i++) {
            _isUserWhitelisted[_info.userWhitelist[i]] = true;
        }

        createdAt = block.number;
    }

    // PUBLIC FUNCTIONS

    /**
     * @dev Purchase pool's tokens during TGE
     * @param amount amount of tokens in wei (10**18 = 1 token)
     */
    function purchase(uint256 amount)
        external
        payable
        onlyWhitelistedUser
        onlyState(State.Active)
        nonReentrant
        whenPoolNotPaused
    {
        // Check purchase price transfer depending on unit of account
        address unitOfAccount = info.unitOfAccount;
        uint256 purchasePrice = (amount * info.price + (1 ether - 1)) / 1 ether;
        if (unitOfAccount == address(0)) {
            require(
                msg.value >= purchasePrice,
                ExceptionsLibrary.INCORRECT_ETH_PASSED
            );
        } else {
            IERC20Upgradeable(unitOfAccount).safeTransferFrom(
                msg.sender,
                address(this),
                purchasePrice
            );
        }

        // Check purchase size
        require(
            amount >= info.minPurchase,
            ExceptionsLibrary.MIN_PURCHASE_UNDERFLOW
        );
        require(
            amount <= maxPurchaseOf(msg.sender),
            ExceptionsLibrary.MAX_PURCHASE_OVERFLOW
        );

        // Accrue TGE stats
        totalPurchased += amount;
        purchaseOf[msg.sender] += amount;

        // Mint tokens directly to user
        uint256 vestedAmount = (amount * info.vestingPercent + (DENOM - 1)) /
            DENOM;
        IToken _token = token;
        if (amount - vestedAmount > 0) {
            _token.mint(msg.sender, amount - vestedAmount);
        }

        // Mint tokens to vesting
        _token.mint(address(this), vestedAmount);
        vestedBalanceOf[msg.sender] += vestedAmount;
        totalVested += vestedAmount;

        // Emit event
        emit Purchased(msg.sender, amount);
    }

    /**
     * @dev Return purchased tokens and get back tokens paid
     */
    function redeem()
        external
        onlyState(State.Failed)
        nonReentrant
        whenPoolNotPaused
    {
        // User can't claim more than he bought in this event (in case somebody else has transferred him tokens)
        require(
            purchaseOf[msg.sender] > 0,
            ExceptionsLibrary.ZERO_PURCHASE_AMOUNT
        );

        uint256 refundAmount = 0;

        // Calculate redeem from vesting
        uint256 vestedBalance = vestedBalanceOf[msg.sender];
        if (vestedBalance > 0) {
            vestedBalanceOf[msg.sender] = 0;
            purchaseOf[msg.sender] -= vestedBalance;
            totalVested -= vestedBalance;
            refundAmount += vestedBalance;
            token.burn(address(this), vestedBalance);
        }

        // Calculate redeemed balance
        uint256 balanceToRedeem = MathUpgradeable.min(
            token.balanceOf(msg.sender),
            purchaseOf[msg.sender]
        );
        if (balanceToRedeem > 0) {
            purchaseOf[msg.sender] -= balanceToRedeem;
            refundAmount += balanceToRedeem;
            token.burn(msg.sender, balanceToRedeem);
        }

        // Check that there is anything to refund
        require(refundAmount > 0, ExceptionsLibrary.NOTHING_TO_REDEEM);

        // Transfer refund value
        uint256 refundValue = (refundAmount * info.price + (1 ether - 1)) /
            1 ether;
        if (info.unitOfAccount == address(0)) {
            payable(msg.sender).sendValue(refundValue);
        } else {
            IERC20Upgradeable(info.unitOfAccount).safeTransfer(
                msg.sender,
                refundValue
            );
        }

        // Emit event
        emit Redeemed(msg.sender, refundValue);
    }

    /**
     * @dev Claim vested tokens
     */
    function claim() external whenPoolNotPaused {
        // Check that vested tokens can be claim
        require(claimAvailable(), ExceptionsLibrary.CLAIM_NOT_AVAILABLE);

        // Check that there is anything to claim
        uint256 amountToClaim = vestedBalanceOf[msg.sender];
        require(amountToClaim > 0, ExceptionsLibrary.NO_LOCKED_BALANCE);

        // Set vested amount to zero
        vestedBalanceOf[msg.sender] = 0;
        totalVested -= amountToClaim;

        // Transfer vested tokens
        IERC20Upgradeable(address(token)).safeTransfer(
            msg.sender,
            amountToClaim
        );

        // Emit event
        emit Claimed(msg.sender, amountToClaim);
    }

    function setVestingTVLReached() external whenPoolNotPaused onlyManager {
        // Check that TVL has not been reached yet
        require(!vestingTVLReached, ExceptionsLibrary.VESTING_TVL_REACHED);

        // Mark as reached
        vestingTVLReached = true;
    }

    function setLockupTVLReached() external whenPoolNotPaused onlyManager {
        // Check that TVL has not been reached yet
        require(!lockupTVLReached, ExceptionsLibrary.LOCKUP_TVL_REACHED);

        // Mark as reached
        lockupTVLReached = true;
    }

    // RESTRICTED FUNCTIONS

    /**
     * @dev Transfer proceeds from TGE to pool's treasury. Claim protocol fee.
     */
    function transferFunds()
        external
        onlyState(State.Successful)
        whenPoolNotPaused
    {
        // Return if nothing to transfer
        if (totalPurchased == 0) {
            return;
        }

        // Claim protocol fee
        _claimProtocolTokenFee();

        // Transfer remaining funds to pool
        address unitOfAccount = info.unitOfAccount;
        address pool = token.pool();
        uint256 balance = 0;
        if (info.price != 0) {
            if (unitOfAccount == address(0)) {
                balance = address(this).balance;
                payable(pool).sendValue(balance);
            } else {
                balance = IERC20Upgradeable(unitOfAccount).balanceOf(
                    address(this)
                );
                IERC20Upgradeable(unitOfAccount).safeTransfer(pool, balance);
            }
        }

        // Emit event
        emit FundsTransferred(balance);
    }

    /// @dev Transfers protocol token fee in form of pool's governance tokens to protocol treasury
    function _claimProtocolTokenFee() private {
        // Return if already claimed
        if (isProtocolTokenFeeClaimed) {
            return;
        }

        // Retrun for preference token
        IToken _token = token;
        if (_token.tokenType() == IToken.TokenType.Preference) {
            return;
        }

        // Mark fee as claimed
        isProtocolTokenFeeClaimed = true;

        // Mint fee to treasury
        uint256 tokenFee = (totalPurchased * protocolFee + (DENOM - 1)) / DENOM;
        _token.mint(_token.service().protocolTreasury(), tokenFee);

        // Emit event
        emit ProtocolTokenFeeClaimed(address(_token), tokenFee);
    }

    // VIEW FUNCTIONS

    /**
     * @dev How many tokens an address can purchase.
     * @return Amount of tokens
     */
    function maxPurchaseOf(address account) public view returns (uint256) {
        if (!isUserWhitelisted(account)) {
            return 0;
        }
        return
            MathUpgradeable.min(
                info.maxPurchase - purchaseOf[account],
                info.hardcap - totalPurchased
            );
    }

    /**
     * @dev Returns TGE's state.
     * @return State
     */
    function state() public view returns (State) {
        // If hardcap is reached TGE is successfull
        if (totalPurchased == info.hardcap) {
            return State.Successful;
        }

        // If deadline not reached TGE is active
        if (block.number < createdAt + info.duration) {
            return State.Active;
        }

        // If it's not primary TGE it's successfull (if anything is purchased)
        if (address(this) != token.getTGEList()[0] && totalPurchased > 0) {
            return State.Successful;
        }

        // If softcap is reached TGE is successfull
        if (totalPurchased >= info.softcap && totalPurchased > 0) {
            return State.Successful;
        }

        // Otherwise it's failed primary TGE
        return State.Failed;
    }

    /**
     * @dev Is claim available for vested tokens.
     * @return Is claim available
     */
    function claimAvailable() public view returns (bool) {
        return
            vestingTVLReached &&
            block.number >= createdAt + info.vestingDuration &&
            (state()) != State.Failed;
    }

    /**
     * @dev Is transfer available for lockup preference tokens.
     * @return Is transfer available
     */
    function transferUnlocked() public view returns (bool) {
        return
            lockupTVLReached && block.number >= createdAt + info.lockupDuration;
    }

    /**
     * @dev Locked balance of account in current TGE
     * @param account Account address
     * @return Locked balance
     */
    function lockedBalanceOf(address account) external view returns (uint256) {
        return
            transferUnlocked()
                ? 0
                : (purchaseOf[account] - vestedBalanceOf[account]);
    }

    /**
     * @dev Get total value of all purchased tokens
     * @return Total value
     */
    function getTotalPurchasedValue() public view returns (uint256) {
        return (totalPurchased * info.price) / 10**18;
    }

    /**
     * @dev Get total value of all vestied tokens
     * @return Total value
     */
    function getTotalVestedValue() public view returns (uint256) {
        return (totalVested * info.price) / 10**18;
    }

    /**
     * @dev Get userwhitelist info
     * @return User whitelist
     */
    function getUserWhitelist() external view returns (address[] memory) {
        return info.userWhitelist;
    }

    /**
     * @dev Checks if user is whitelisted
     * @param account User address
     * @return Flag if user if whitelisted
     */
    function isUserWhitelisted(address account) public view returns (bool) {
        return info.userWhitelist.length == 0 || _isUserWhitelisted[account];
    }

    // MODIFIER

    modifier onlyState(State state_) {
        require(state() == state_, ExceptionsLibrary.WRONG_STATE);
        _;
    }

    modifier onlyWhitelistedUser() {
        require(
            isUserWhitelisted(msg.sender),
            ExceptionsLibrary.NOT_WHITELISTED
        );
        _;
    }

    modifier onlyManager() {
        IService service = token.service();
        require(
            service.hasRole(service.SERVICE_MANAGER_ROLE(), msg.sender),
            ExceptionsLibrary.NOT_WHITELISTED
        );
        _;
    }

    modifier whenPoolNotPaused() {
        require(
            !IPool(token.pool()).paused(),
            ExceptionsLibrary.SERVICE_PAUSED
        );
        _;
    }
}
