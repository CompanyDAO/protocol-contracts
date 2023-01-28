// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20CappedUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20VotesUpgradeable.sol";
import "./interfaces/IService.sol";
import "./interfaces/IToken.sol";
import "./interfaces/ITGE.sol";
import "./interfaces/IPool.sol";
import "./interfaces/registry/IRegistry.sol";
import "./libraries/ExceptionsLibrary.sol";

/// @dev Company (Pool) Token
contract Token is ERC20CappedUpgradeable, ERC20VotesUpgradeable, IToken {
    /// @dev Service address
    IService public service;

    /// @dev Pool address
    address public pool;

    /// @dev Token type
    TokenType public tokenType;

    /// @dev Preference token description, allows up to 5000 characters, for others - ""
    string public description;

    /// @dev List of all TGEs
    address[] public tgeList;

    /// @dev Token decimals
    uint8 private _decimals;

    // INITIALIZER AND CONSTRUCTOR

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Constructor function, can only be called once
     * @param pool_ Pool
     * @param info Token info struct
     * @param primaryTGE_ Primary tge address
     */
    function initialize(
        address pool_,
        TokenInfo memory info,
        address primaryTGE_
    ) external initializer {
        __ERC20Capped_init(info.cap);

        if (info.tokenType == TokenType.Preference) {
            __ERC20_init(info.name, info.symbol);
            description = info.description;
            _decimals = info.decimals;
        } else {
            __ERC20_init(IPool(pool_).trademark(), info.symbol);
        }

        tgeList.push(primaryTGE_);
        tokenType = info.tokenType;
        service = IService(msg.sender);
        pool = pool_;
    }

    // RESTRICTED FUNCTIONS

    /**
     * @dev Mint token
     * @param to Recipient
     * @param amount Amount of tokens
     */
    function mint(address to, uint256 amount) external onlyTGE {
        // Delegate to self if first mint andno delegatee set
        if (tokenType == IToken.TokenType.Governance) {
            if (balanceOf(to) == 0 && delegates(to) == address(0))
                _delegate(to, to);
        }

        // Mint tokens
        _mint(to, amount);
    }

    /**
     * @dev Burn token
     * @param from Target
     * @param amount Amount of tokens
     */
    function burn(address from, uint256 amount) external whenPoolNotPaused {
        // Check that sender is valid
        require(
            service.registry().typeOf(msg.sender) ==
                IRecordsRegistry.ContractType.TGE ||
                msg.sender == from,
            ExceptionsLibrary.INVALID_USER
        );

        // Burn tokens
        _burn(from, amount);
    }

    /**
     * @dev Add TGE to TGE archive list
     * @param tge TGE address
     */
    function addTGE(address tge) external onlyService {
        tgeList.push(tge);
    }

    // PUBLIC VIEW FUNCTIONS

    /**
     * @dev Return decimals
     * @return Decimals
     */
    function decimals()
        public
        view
        override(ERC20Upgradeable, IToken)
        returns (uint8)
    {
        if (tokenType == TokenType.Governance) {
            return 18;
        } else {
            return _decimals;
        }
    }

    /**
     * @dev Return cap
     * @return Cap
     */
    function cap()
        public
        view
        override(IToken, ERC20CappedUpgradeable)
        returns (uint256)
    {
        return super.cap();
    }

    /**
     * @dev Return cap
     * @return Cap
     */
    function symbol()
        public
        view
        override(IToken, ERC20Upgradeable)
        returns (string memory)
    {
        return super.symbol();
    }

    /**
     * @dev Returns unlocked balance of account
     * @param account Account address
     * @return Unlocked balance of account
     */
    function unlockedBalanceOf(address account) public view returns (uint256) {
        // Get total account balance
        uint256 balance = balanceOf(account);

        // Iterate through TGE list to get locked balance
        address[] memory _tgeList = tgeList;
        uint256 totalLocked = 0;
        for (uint256 i; i < _tgeList.length; i++) {
            if (ITGE(_tgeList[i]).state() != ITGE.State.Failed)
                totalLocked += ITGE(tgeList[i]).lockedBalanceOf(account);
        }

        // Return difference
        return balance - totalLocked;
    }

    /**
     * @dev Return if pool had a successful TGE
     * @return Is any TGE successful
     */
    function isPrimaryTGESuccessful() external view returns (bool) {
        return (ITGE(tgeList[0]).state() == ITGE.State.Successful);
    }

    /**
     * @dev Return list of pool's TGEs
     * @return TGE list
     */
    function getTGEList() external view returns (address[] memory) {
        return tgeList;
    }

    /**
     * @dev Return list of pool's TGEs
     * @return TGE list
     */
    function lastTGE() external view returns (address) {
        return tgeList[tgeList.length - 1];
    }

    /**
     * @dev Return amount of tokens currently vested in TGE vesting contract(s)
     * @return Total vesting tokens
     */
    function getTotalTGEVestedTokens() public view returns (uint256) {
        address[] memory _tgeList = tgeList;
        uint256 totalVested = 0;
        for (uint256 i; i < _tgeList.length; i++) {
            totalVested += ITGE(_tgeList[i]).totalVested();
        }
        return totalVested;
    }

    // INTERNAL FUNCTIONS

    /**
     * @dev Transfer tokens from a given user.
     * Check to make sure that transfer amount is less or equal
     * to least amount of unlocked tokens for any proposal that user might have voted for.
     * @param from User address
     * @param to Recipient address
     * @param amount Amount of tokens
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override whenPoolNotPaused {
        // Check that locked tokens are not transferred
        require(
            amount <= unlockedBalanceOf(from),
            ExceptionsLibrary.LOW_UNLOCKED_BALANCE
        );

        if (tokenType == IToken.TokenType.Governance) {
            if (balanceOf(to) == 0 && delegates(to) == address(0))
                _delegate(to, to);
        }

        // Execute transfer
        super._transfer(from, to, amount);
    }

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20Upgradeable, ERC20VotesUpgradeable) {
        super._afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     */
    function _mint(address account, uint256 amount)
        internal
        override(ERC20VotesUpgradeable, ERC20CappedUpgradeable)
    {
        super._mint(account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     */
    function _burn(address account, uint256 amount)
        internal
        override(ERC20Upgradeable, ERC20VotesUpgradeable)
    {
        super._burn(account, amount);
    }

    // MODIFIERS

    modifier onlyPool() {
        require(msg.sender == pool, ExceptionsLibrary.NOT_POOL);
        _;
    }

    modifier onlyService() {
        require(msg.sender == address(service), ExceptionsLibrary.NOT_SERVICE);
        _;
    }

    modifier onlyTGE() {
        require(
            service.registry().typeOf(msg.sender) ==
                IRecordsRegistry.ContractType.TGE,
            ExceptionsLibrary.NOT_TGE
        );
        _;
    }

    modifier whenPoolNotPaused() {
        require(!IPool(pool).paused(), ExceptionsLibrary.SERVICE_PAUSED);
        _;
    }
}
