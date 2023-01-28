// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "./governor/GovernorProposals.sol";
import "./interfaces/IService.sol";
import "./interfaces/IPool.sol";
import "./interfaces/IToken.sol";
import "./interfaces/ITGE.sol";
import "./interfaces/registry/IRecordsRegistry.sol";
import "./libraries/ExceptionsLibrary.sol";

/// @dev Company Entry Point
contract Pool is
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable,
    GovernorProposals,
    IPool
{
    /// @dev Pool trademark
    string public trademark;

    /// @dev Company info
    IRegistry.CompanyInfo public companyInfo;

    /// @dev Pool tokens addresses
    mapping(IToken.TokenType => address) public tokens;

    // EVENTS

    /**
     * @dev Event emitted when pool contract receives ETH.
     * @param amount Amount of received ETH
     */
    event Received(uint256 amount);

    // MODIFIER

    modifier onlyService() {
        require(msg.sender == address(service), ExceptionsLibrary.NOT_SERVICE);
        _;
    }

    modifier onlyServiceAdmin() {
        require(
            service.hasRole(service.ADMIN_ROLE(), msg.sender),
            ExceptionsLibrary.NOT_SERVICE_OWNER
        );
        _;
    }

    modifier onlyPool() {
        require(msg.sender == address(this), ExceptionsLibrary.NOT_POOL);
        _;
    }

    modifier onlyExecutor(uint256 proposalId) {
        if (
            proposals[proposalId].meta.proposalType ==
            IRecordsRegistry.EventType.Transfer
        ) {
            require(
                service.hasRole(service.EXECUTOR_ROLE(), msg.sender),
                ExceptionsLibrary.INVALID_USER
            );
        }
        _;
    }
    
    modifier onlyState(PoolState state_) {
        require(state() == state_, ExceptionsLibrary.WRONG_POOL_STATE);
        _;
    }
    // INITIALIZER AND CONFIGURATOR

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Create TransferETH proposal
     * @param companyInfo_ Company info
     * @param owner_ Pool owner
     * @param trademark_ Trademark
     * @param governanceSettings_ GovernanceSettings_
     */
    function initialize(
        address owner_,
        string memory trademark_,
        NewGovernanceSettings memory governanceSettings_,
        IRegistry.CompanyInfo memory companyInfo_
    ) external initializer {
        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();
        __GovernorProposals_init(IService(msg.sender));

        _transferOwnership(owner_);
        trademark = trademark_;
        _setGovernanceSettings(governanceSettings_);
        companyInfo = companyInfo_;
    }

    // RECEIVE

    receive() external payable {
        emit Received(msg.value);
    }

    // PUBLIC FUNCTIONS

    /**
     * @dev Cast proposal vote
     * @param proposalId Pool proposal ID
     * @param support Against or for
     */
    function castVote(uint256 proposalId, bool support)
        external
        nonReentrant
        whenNotPaused
    {
        _castVote(proposalId, support);
    }

    // RESTRICTED PUBLIC FUNCTIONS

    /**
     * @dev Set pool preference token
     * @param token_ Token address
     * @param tokenType_ Token type
     */
    function setToken(address token_, IToken.TokenType tokenType_)
        external
        onlyService
    {
        require(token_ != address(0), ExceptionsLibrary.ADDRESS_ZERO);

        tokens[tokenType_] = token_;
    }

    /**
     * @dev Execute proposal
     * @param proposalId Proposal ID
     */
    function executeProposal(uint256 proposalId)
        external
        whenNotPaused
        onlyExecutor(proposalId)
    {
        _executeProposal(proposalId, service);
    }

    /**
     * @dev Cancel proposal, callable only by Service
     * @param proposalId Proposal ID
     */
    function cancelProposal(uint256 proposalId) external onlyService {
        _cancelProposal(proposalId);
    }

    /**
     * @dev Pause pool and corresponding TGEs and Tokens
     */
    function pause() public onlyServiceAdmin {
        _pause();
    }

    /**
     * @dev Pause pool and corresponding TGEs and Tokens
     */
    function unpause() public onlyServiceAdmin {
        _unpause();
    }

    // PUBLIC VIEW FUNCTIONS

    /**
     * @dev Return if pool had a successful governance TGE
     * @return Is any governance TGE successful
     */
    function isDAO() public view returns (bool) {
        return
            IToken(tokens[IToken.TokenType.Governance])
                .isPrimaryTGESuccessful();
    }
    
    /**
     * @dev Returns Pool's state.
     * @return PoolState
     */
    function state() public view returns (PoolState) {
        // Check if Pool is paused
        if (paused()) {
            // Return Paused state if true
            return PoolState.Paused;
        }
        // Check if  Pool is Dao
        if (isDAO()) {
            // Return Dao state if true
            return PoolState.Dao;
        }
        // Check if Pool has Governance Tokens
        if (tokens[IToken.TokenType.Governance] != address(0)) {
            // Return PoolwithToken state if true
            return PoolState.PoolwithToken;
        }
        // Default PoolState
        return PoolState.Pool;
    }
    /**
     * @dev Return pool owner
     * @return Owner address
     */
    function owner()
        public
        view
        override(IPool, OwnableUpgradeable)
        returns (address)
    {
        return super.owner();
    }

    function getToken(IToken.TokenType tokenType)
        external
        view
        returns (IToken)
    {
        return IToken(tokens[tokenType]);
    }

    // INTERNAL FUNCTIONS

    function _afterProposalCreated(uint256 proposalId) internal override {
        service.addProposal(proposalId);
    }

    /**
     * @dev Function that gets amount of votes for given account
     * @param account Account's address
     * @return Amount of votes
     */
    function _getCurrentVotes(address account)
        internal
        view
        override
        returns (uint256)
    {
        return IToken(tokens[IToken.TokenType.Governance]).getVotes(account);
    }

    /**
     * @dev Function that gets total amount of votes at the moment
     * @return Amont of votes
     */
    function _getCurrentTotalVotes() internal view override returns (uint256) {
        IToken token = IToken(tokens[IToken.TokenType.Governance]);
        return token.totalSupply() - token.getTotalTGEVestedTokens();
    }

    /**
     * @dev Function that gets amount of votes for given account at given block
     * @param account Account's address
     * @param blockNumber Block number
     * @return Account's votes at given block
     */
    function _getPastVotes(address account, uint256 blockNumber)
        internal
        view
        override
        returns (uint256)
    {
        return
            IToken(tokens[IToken.TokenType.Governance]).getPastVotes(
                account,
                blockNumber
            );
    }

    /**
     * @dev Return pool paused status
     * @return Is pool paused
     */
    function paused()
        public
        view
        override(IPool, PausableUpgradeable)
        returns (bool)
    {
        // Pausable
        return super.paused();
    }
}
