// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "./governor/GovernorProposals.sol";
import "./interfaces/IService.sol";
import "./interfaces/IPool.sol";
import "./interfaces/IToken.sol";
import "./interfaces/ITGE.sol";
import "./interfaces/ICustomProposal.sol";
import "./interfaces/registry/IRecordsRegistry.sol";
import "./libraries/ExceptionsLibrary.sol";
import "./utils/Logger.sol";

/**
    * @title Pool Contract
    * @notice These contracts are instances of on-chain implementations of user companies. The shareholders of the companies work with them, their addresses are used in the Registry contract as tags that allow obtaining additional legal information (before the purchase of the company by the client). They store legal data (after the purchase of the company by the client). Among other things, the contract is also the owner of the Token and TGE contracts.
    * @dev There can be an unlimited number of such contracts, including for one company owner. The contract can be in three states:
    * 1) the company was created by the administrator, a record of it is stored in the Registry, but the contract has not yet been deployed and does not have an owner (buyer) 
    * 2) the contract is deployed, the company has an owner, but there is not yet a successful (softcap primary TGE), in this state its owner has the exclusive right to recreate the TGE in case of their failure (only one TGE can be launched at the same time) 
    * 3) the primary TGE ended successfully, softcap is assembled - the company has received the status of DAO.    The owner no longer has any exclusive rights, all the actions of the company are carried out through the creation and execution of propousals after voting. In this status, the contract is also a treasury - it stores the company's values in the form of ETH and/or ERC20 tokens.
    * @dev The "Pool owner" status is temporary and is assigned to the address that has successfully purchased a company and in which there has not been a single successful TGE Governance Token. The current owner's address of the company can be obtained by referring to the owner method of the Pool contract. If the isDAO method of the same contract returns "true", then this status does not grant any privileges or exclusive rights and has more of a historical and reference nature.
    As long as the pool is not considered a DAO, the address which is having this status can interact with such methods:
    - TGEFactory.sol:createPrimaryTGE(address poolAddress, IToken.TokenInfo memory tokenInfo, ITGE.TGEInfo memory tgeInfo, string memory metadataURI, IGovernanceSettings.NewGovernanceSettings memory governanceSettings_, address[] memory addSecretary, address[] memory addExecutor) - this method allows you to create a Governance Token compatible with ERC20, with a full set of standard settings, launch a primary TGE for it by deploying the corresponding contract, and also fully configure Governance using the NewGovernanceSettings structure and arrays of addSecretary and addExecutor addresses. The rules set for Governance will become relevant immediately after the successful completion of this primary TGE.
    - Pool.sol:transferByOwner(address to, uint256 amount, address unitOfAccount) - this method allows you to withdraw ETH or any ERC20 token from the pool contract to any address specified by the owner
    Moreover, while in this status, the pool owner, who has not yet become a DAO, can create invoices without restrictions using the Invoice:createInvoice(address pool, InvoiceCore memory core) method.
    In case of a primary TGE failure, the company owner continues to use their unique status, which means they can recreate the token, TGE, and set new Governance settings within a single transaction.
    */
contract Pool is
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable,
    GovernorProposals,
    IPool,
    Logger
{
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using AddressUpgradeable for address;
    using AddressUpgradeable for address payable;
    /// @dev The company's trade mark, label, brand name. It also acts as the Name of all the Governance tokens created for this pool.
    string public trademark;

    /// @dev When a buyer acquires a company, its record disappears from the Registry contract, but before that, the company's legal data is copied to this variable.
    ICompaniesRegistry.CompanyInfo public companyInfo;

    /// @dev Mapping for Governance Token. There can be only one valid Governance token.
    mapping(IToken.TokenType => address) public tokens;

    /// @dev last proposal id for address. This method returns the proposal Id for the last proposal created by the specified address.
    mapping(address => uint256) public lastProposalIdForAddress;

    /// @dev Mapping that stores the blocks of proposal creation for this pool. The main information about the proposal is stored in variables provided by the Governor.sol contract, which is inherited by this contract.
    mapping(uint256 => uint256) public proposalCreatedAt;

    /// @dev A list of tokens belonging to this pool. There can be only one valid Governance token and several Preference tokens with different settings. The mapping key is the token type (token type encoding is specified in the IToken.sol interface). The value is an array of token identifiers.
    mapping(IToken.TokenType => address[]) public tokensFullList;

    /// @dev Mapping that stores information about the type of each token. The mapping key is the address of the token contract, and the value is the digital code of the token type.
    mapping(address => IToken.TokenType) public tokenTypeByAddress;

    EnumerableSetUpgradeable.AddressSet gap_AddressSet_1;

    /// @dev Identifier of the last executed proposal
    uint256 public lastExecutedProposalId;

    /// @dev Mapping that stores the addresses of TGE contracts that have been deployed as part of proposal execution, using the identifiers of those proposals as keys.
    mapping(uint256 => address) public proposalIdToTGE;

    EnumerableSetUpgradeable.AddressSet gap_AddressSet_2;

    /// @dev DAO Metadata Uri
    string public DAOmetadataURI;

    //address public dividendsManager;

    mapping(uint256 => EnumerableSetUpgradeable.AddressSet) private roles; // 0 - manager role,  1 - secretary , 2 - executor role, 3 - dividend manager role

    // EVENTS

    // MODIFIER

    /// @notice Modifier that allows the method to be called only by the Service contract.
    /// @dev It is used to transfer control of the Registry and deployable user contracts for the final configuration of the company.
    modifier onlyService() {
        require(msg.sender == address(service), ExceptionsLibrary.NOT_SERVICE);
        _;
    }

    /// @notice Modifier that allows the method to be called only by the TGEFactory contract.
    /// @dev Used during TGE creation, where the TGEFactory contract deploys contracts and informs their addresses to the pool contract for storage.
    modifier onlyTGEFactory() {
        require(
            msg.sender == address(service.tgeFactory()),
            ExceptionsLibrary.NOT_TGE_FACTORY
        );
        _;
    }

    // INITIALIZER AND CONFIGURATOR

    /// @custom:oz-upgrades-unsafe-allow constructor

    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Initialization of a new pool and placement of user settings and data (including legal ones) in it
     * @param companyInfo_ Legal company data
     */
    function initialize(
        ICompaniesRegistry.CompanyInfo memory companyInfo_
    ) external initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        __Pausable_init();
        service = IService(msg.sender);
        companyInfo = companyInfo_;
    }

    /**
    * @notice Actions after purchasing a pool (including ownership transfer and governance settings)
    * @dev This is executed only during a successful execution of purchasePool in the Service contract. The address that is mentioned in the 'newowner' field of the transaction calldata becomes the pool owner.
    * @dev An internal pool role, relevant from the moment of purchasing a company until the first successful TGE. The sole and unchangeable wallet possessing this role is the account that paid the fee for creating the company. Once the pool becomes a DAO, this role no longer has any exclusive powers.

    The appointment of the Owner's address is done within the call to Pool.sol:setNewOwnerWithSettings(address newowner, string memory trademark_, NewGovernanceSettings memory governanceSettings_), which occurs when a new owner purchases the company.
    * @param newowner Address of the new contract owner account
    * @param trademark_ Company trademark
    * @param governanceSettings_ Governance settings (voting rules, etc.)
    */
    function setNewOwnerWithSettings(
        address newowner,
        string memory trademark_,
        NewGovernanceSettings memory governanceSettings_,
        bool forceTransfer
    ) external onlyService {
        require(forceTransfer || bytes(trademark).length == 0, ExceptionsLibrary.ALREADY_SET);
        _transferOwnership(address(newowner));
        trademark = trademark_;
        _setGovernanceSettings(governanceSettings_);
    }

    /**
     * @notice Changing the governance settings of the pool as a result of voting or the owner's initial pool setup
     * @dev This method can be called in one of two cases:
     * - The pool has attained DAO status, and a proposal including a transaction calling this method has been executed
     * - The pool has not yet attained DAO status, and the pool owner initiates the initial TGE with new governance settings as arguments
     * @param governanceSettings_ Governance settings
     * @param _roles Roles addresses
     */
    function setSettings(
        NewGovernanceSettings memory governanceSettings_,
        ITGEFactory.Roles memory _roles
    ) external {
        //only tgeFactory or pool
        require(
            msg.sender == address(service.tgeFactory()) ||
                msg.sender == address(this),
            ExceptionsLibrary.NOT_TGE_FACTORY
        );
        if (msg.sender == address(service.tgeFactory())) {
            if (address(getGovernanceToken()) != address(0)) {
                require(!isDAO(), ExceptionsLibrary.IS_DAO);
                require(
                    ITGE(getGovernanceToken().lastTGE()).state() !=
                        ITGE.State.Active,
                    ExceptionsLibrary.ACTIVE_TGE_EXISTS
                );
            }
        }
        _setGovernanceSettings(governanceSettings_);

        // 0 - manager role,  1 - secretary , 2 - executor role, 3 - dividend manager role

        updateRoleMembers(0, _roles.manager); // Update manager role
        updateRoleMembers(1, _roles.secretary); // Update secretary role
        updateRoleMembers(2, _roles.executor); // Update executor role
    }

    // Define a function to update role members
    function updateRoleMembers(
        uint256 roleIndex,
        address[] memory newMembers
    ) private {
        address[] memory existingMembers = roles[roleIndex].values();
        for (uint256 i = 0; i < existingMembers.length; i++) {
            roles[roleIndex].remove(existingMembers[i]);
        }

        for (uint256 i = 0; i < newMembers.length; i++) {
            roles[roleIndex].add(newMembers[i]);
        }
    }

    /**
     * @notice Setting legal data for the corresponding company pool
     * @dev This method is executed as part of the internal transaction in the setCompanyInfoForPool method of the Registry contract
     * @param _jurisdiction Digital code of the jurisdiction
     * @param _entityType Digital code of the organization type
     * @param _ein Government registration number of the company
     */
    function setCompanyInfo(
        uint256 _fee,
        uint256 _jurisdiction,
        uint256 _entityType,
        string memory _ein
    ) external {
        require(
            msg.sender == address(service.registry()),
            ExceptionsLibrary.NOT_REGISTRY
        );
        companyInfo.jurisdiction = _jurisdiction;
        companyInfo.entityType = _entityType;
        companyInfo.ein = _ein;
        companyInfo.fee = _fee;
    }

    function setDAOmetadataURI(string memory _OAuri) external onlyService {
        DAOmetadataURI = _OAuri;
    }

    // RECEIVE
    /// @dev Method for receiving an Ethereum contract that issues an event.
    receive() external payable {}

    // PUBLIC FUNCTIONS

    /**
     * @notice Method for voting "for" or "against" a given proposal
     * @dev This method calls the _castVote function defined in the Governor.sol contract.
     * @dev Since proposals in the CompanyDAO protocol can be prematurely finalized, after each successful invocation of this method, a check is performed for the occurrence of such conditions.
     * @param proposalId Pool proposal ID
     * @param support "True" for voting "for", "False" for voting "against"
     */
    function castVote(
        uint256 proposalId,
        bool support
    ) external nonReentrant whenNotPaused {
        _castVote(msg.sender, proposalId, support);

        emit CompanyDAOLog(
            msg.sender,
            address(this),
            0,
            abi.encodeWithSelector(IPool.castVote.selector, proposalId, support),
            address(service)
        );
    }

    function externalCastVote(
        address account,
        uint256 proposalId,
        bool support
    ) external whenNotPaused onlyService {
        _castVote(account, proposalId, support);
    }

    // RESTRICTED PUBLIC FUNCTIONS

    /**
     * @dev Adding a new entry about the deployed token contract to the list of tokens related to the pool.
     * @param token_ Token address
     * @param tokenType_ Token type
     */
    function setToken(
        address token_,
        IToken.TokenType tokenType_
    ) external onlyTGEFactory {
        require(token_ != address(0), ExceptionsLibrary.ADDRESS_ZERO);
        if (tokenExists(token_)) return;
        if (tokenType_ == IToken.TokenType.Governance) {
            // Check that there is no governance tokens or tge failed
            require(
                address(getGovernanceToken()) == address(0) ||
                    ITGE(getGovernanceToken().getTGEList()[0]).state() ==
                    ITGE.State.Failed,
                ExceptionsLibrary.GOVERNANCE_TOKEN_EXISTS
            );
            tokens[IToken.TokenType.Governance] = token_;
            if (tokensFullList[tokenType_].length > 0) {
                tokensFullList[tokenType_].pop();
            }
        }
        tokensFullList[tokenType_].push(token_);
        tokenTypeByAddress[address(token_)] = tokenType_;
    }

    /**
     * @dev This method adds a record to the proposalIdToTGE mapping indicating that a TGE contract with the specified address was deployed as a result of executing the proposal with the lastExecutedProposalId identifier.
     * @param tge TGE address
     */
    function setProposalIdToTGE(address tge) external onlyTGEFactory {
        proposalIdToTGE[lastExecutedProposalId] = tge;
    }

    /**
    * @notice This method is used to initiate the execution of a proposal.
    * @dev For this method to work, the following conditions must be met:
    - The transaction sender must be a valid executor (more details in the isValidExecutor function)
    - The proposal must have the "Awaiting Execution" status.
    * @param proposalId Proposal ID
    */
    function executeProposal(uint256 proposalId) external whenNotPaused {
        require(
            isValidExecutor(msg.sender),
            ExceptionsLibrary.NOT_VALID_EXECUTOR
        );

        lastExecutedProposalId = proposalId;
        _executeProposal(proposalId, service);

        emit CompanyDAOLog(
            msg.sender,
            address(this),
            0,
            abi.encodeWithSelector(IPool.executeProposal.selector, proposalId),
            address(service)
        );
    }

    /**
     * @notice Method for emergency cancellation of a proposal.
     * @dev Cancel a proposal, callable only by the Service contract.
     * @param proposalId Proposal ID
     */
    // function cancelProposal(uint256 proposalId) external onlyService {
    //     _cancelProposal(proposalId);
    // }

    /**
     * @dev Creating a proposal and assigning it a unique identifier to store in the list of proposals in the Governor contract.
     * @param core Proposal core data
     * @param meta Proposal meta data
     */
    function propose(
        address proposer,
        uint256 proposeType,
        IGovernor.ProposalCoreData memory core,
        IGovernor.ProposalMetaData memory meta
    ) external returns (uint256 proposalId) {
        require(
            msg.sender == address(service.customProposal()) &&
                isValidProposer(proposer),
            ExceptionsLibrary.NOT_VALID_PROPOSER
        );

        core.quorumThreshold = quorumThreshold;
        core.decisionThreshold = decisionThreshold;
        core.executionDelay = executionDelays[meta.proposalType];
        uint256 proposalId_ = _propose(
            core,
            meta,
            votingDuration,
            votingStartDelay
        );
        lastProposalIdByType[proposeType] = proposalId_;

        _setLastProposalIdForAddress(proposer, proposalId_);

        emit CompanyDAOLog(
            proposer,
            address(this),
            0,
            abi.encodeWithSelector(
                IPool.propose.selector,
                proposer,
                proposeType,
                core,
                meta
            ),
            address(service)
        );

        return proposalId_;
    }

    /**
     * @notice Transfers funds from the pool's account to a specified address.
     * @dev This method can only be called by the pool owner and only during the period before the pool becomes a DAO.
     * @param to The recipient's address
     * @param amount The transfer amount
     * @param unitOfAccount The unit of account (token contract address or address(0) for ETH)
     */
    function transferByOwner(
        address to,
        uint256 amount,
        address unitOfAccount
    ) external onlyOwner {
        require(!isDAO(), ExceptionsLibrary.IS_DAO);
        _transferByOwner(to, amount, unitOfAccount);
    }

    // function externalTransferByOwner(
    //     address to,
    //     uint256 amount,
    //     address unitOfAccount
    // ) external onlyService {
    //     require(!isDAO(), ExceptionsLibrary.IS_DAO);
    //     _transferByOwner(to, amount, unitOfAccount);
    // }

    function _transferByOwner(
        address to,
        uint256 amount,
        address unitOfAccount
    ) internal {
        //only if pool is yet DAO

        if (unitOfAccount == address(0)) {
            require(
                address(this).balance >= amount,
                ExceptionsLibrary.WRONG_AMOUNT
            );

            (bool success, ) = payable(to).call{value: amount}("");
            require(success, ExceptionsLibrary.WRONG_AMOUNT);
        } else {
            require(
                IERC20Upgradeable(unitOfAccount).balanceOf(address(this)) >=
                    amount,
                ExceptionsLibrary.WRONG_AMOUNT
            );

            IERC20Upgradeable(unitOfAccount).safeTransferFrom(
                address(this),
                to,
                amount
            );
        }
    }

    // PUBLIC VIEW FUNCTIONS

    /**
     * @dev Checks if the pool has achieved DAO status.
     * A pool achieves DAO status if it has a valid governance token and the primary TGE was successful.
     * @return isDao True if the pool is a DAO, false otherwise.
     */
    function isDAO() public view returns (bool) {
        if (address(getGovernanceToken()) == address(0)) {
            return false;
        } else {
            return getGovernanceToken().isPrimaryTGESuccessful();
        }
    }

    function getCompanyFee() public view returns (uint256) {
        return companyInfo.fee;
    }

    /**
     * @dev Returns the owner of the pool.
     * @return The address of the pool owner.
     */
    function owner()
        public
        view
        override(IPool, OwnableUpgradeable)
        returns (address)
    {
        return super.owner();
    }

    /**
     * @dev Returns the list of tokens associated with the pool based on the token type.
     * @param tokenType The type of tokens to retrieve.
     * @return The array of token addresses.
     */
    function getTokens(
        IToken.TokenType tokenType
    ) external view returns (address[] memory) {
        return tokensFullList[tokenType];
    }

    /**
     * @dev Returns the governance token associated with the pool.
     * @return The governance token address.
     */
    function getGovernanceToken() public view returns (IToken) {
        return IToken(tokens[IToken.TokenType.Governance]);
    }

    /**
     * @dev Checks if a token exists in the pool.
     * @param token The token to check.
     * @return True if the token exists, false otherwise.
     */
    function tokenExists(address token) public view returns (bool) {
        return
            tokenTypeByAddress[token] == IToken.TokenType.None ? false : true;
    }

    // 0 - manager role,  1 - secretary , 2 - executor role, 3 - dividend manager role
    // function getPoolRoleMembers(
    //     uint256 roleId
    // ) external view returns (address[] memory) {
    //     return isDAO() ? roles[roleId].values() : new address[](0);
    // }

    /**
     * @dev Returns the list of pool secretaries.
     * @return The array of pool secretary addresses.
     */
    function getPoolSecretary() external view returns (address[] memory) {
        return isDAO() ? roles[1].values() : new address[](0);
    }

    /**
     * @dev Returns the list of pool executors.
     * @return The array of pool executor addresses.
     */
    function getPoolExecutor() external view returns (address[] memory) {
        return isDAO() ? roles[2].values() : new address[](0);
    }

    function getPoolManager() external view returns (address[] memory) {
        return isDAO() ? roles[0].values() : new address[](0);
    }

    // function getDividendManager() external view returns (address[] memory) {
    //     return isDAO() ? roles[3].values() : new address[](0);
    // }

    /**
     * @dev Checks if an address is a pool secretary.
     * This function determines if a given address is a pool secretary based on their roles and the status of the pool.
     * If the pool is a DAO, it checks if the address is in the poolSecretary set. If the pool is not a DAO, it checks if the address is the owner.
     *
     * @param account The address to check.
     * @return True if the address is a pool secretary, false otherwise.
     */
    function isPoolSecretary(address account) public view returns (bool) {
        if (isDAO()) {
            return
                roles[0].contains(account) ||
                roles[1].contains(account) ||
                account == address(service);
        }

        return account == owner();
    }

    /**
     * @dev Checks if an address is a pool executor.
     * @param account The address to check.
     * @return True if the address is a pool executor, false otherwise.
     */
    // function isPoolExecutor(address account) public view returns (bool) {
    //     return isDAO() ? roles[2].contains(account) : false;
    // }

    /**
     * @dev Checks if an address is a valid proposer for creating proposals.
     * @param account The address to check.
     * @return True if the address is a valid proposer, false otherwise.
     */
    function isValidProposer(address account) public view returns (bool) {
        uint256 currentVotes = getCurrentVotes(account);
        return
            isPoolSecretary(account) ||
            (currentVotes > 0 && currentVotes > proposalThreshold);
    }

    /**
     * @dev Checks if an address is a valid executor for executing ballot proposals.
     * @param account The address to check.
     * @return True if the address is a valid executor, false otherwise.
     */
    function isValidExecutor(address account) private view returns (bool) {
        if (roles[2].length() == 0 || roles[2].contains(account)) return true;

        return false;
    }

    // function isValidDividendManager(
    //     address account
    // ) public view returns (bool) {
    //     if (
    //         roles[3].length() == 0 ||
    //         (isDAO() ? roles[3].contains(account) : false) ||
    //         service.hasRole(service.SERVICE_MANAGER_ROLE(), account)
    //     ) return true;

    //     return false;
    // }

    /**
     * @dev Checks if the last proposal of a specific type is active.
     * @param type_ The type of proposal.
     * @return True if the last proposal of the given type is active, false otherwise.
     */
    function isLastProposalIdByTypeActive(
        uint256 type_
    ) public view returns (bool) {
        if (proposalState(lastProposalIdByType[type_]) == ProposalState.Active)
            return true;

        return false;
    }

    /**
     * @dev Validates the governance settings for creating proposals.
     * @param settings The governance settings to validate.
     */
    function validateGovernanceSettings(
        NewGovernanceSettings memory settings
    ) external pure {
        _validateGovernanceSettings(settings);
    }

    /**
     * @dev Returns the available votes for a proposal at the current block.
     * @param proposalId The ID of the proposal.
     * @return The available votes for the proposal.
     */
    function availableVotesForProposal(
        uint256 proposalId
    ) external view returns (uint256) {
        if (proposals[proposalId].vote.startBlock - 1 < block.number)
            return
                _getBlockTotalVotes(proposals[proposalId].vote.startBlock - 1);
        else return _getBlockTotalVotes(block.number - 1);
    }

    /**
     * @dev Return pool paused status
     * @return Is pool paused
     */
    function paused() public view override returns (bool) {
        // Pausable
        return super.paused();
    }

    // INTERNAL FUNCTIONS

    /**
     * @dev Internal function to be called after a proposal is created.
     * @param proposalId The ID of the created proposal.
     */
    function _afterProposalCreated(uint256 proposalId) internal override {
        service.addProposal(proposalId);
    }

    /**
     * @dev Internal function to get the current votes of an account.
     * @param account The account's address.
     * @return The current votes of the account.
     */
    function getCurrentVotes(address account) public view returns (uint256) {
        return getGovernanceToken().getVotes(account);
    }

    /**
     * @dev Internal function to get the total votes in the pool at a specific block.
     * @param blocknumber The block number.
     * @return The total votes at the given block.
     */
    function _getBlockTotalVotes(
        uint256 blocknumber
    ) internal view override returns (uint256) {
        return getGovernanceToken().getPastTotalSupply(blocknumber);
    }

    // /**
    //  * @dev Internal function to get the past votes of an account at a specific block.
    //  * @param account The account's address.
    //  * @param blockNumber The block number.
    //  * @return The past votes of the account at the given block.
    //  */
    // function _getPastVotes(
    //     address account,
    //     uint256 blockNumber
    // ) internal view override returns (uint256) {
    //     if (roles[0].length() == 0) {
    //         return getGovernanceToken().getPastVotes(account, blockNumber);
    //     } else if (roles[3].contains(account)) {
    //         return getGovernanceToken().getPastTotalSupply(blockNumber);
    //     }
    //     return 0;
    // }

    function _getPastVotesForProposal(
        address account,
        uint256 proposalId
    ) internal view override returns (uint256) {
        if (
            roles[0].length() == 0 ||
            proposals[proposalId].meta.proposalType ==
            IRecordsRegistry.EventType.GovernanceSettings
        ) {
            return
                getGovernanceToken().getPastVotes(
                    account,
                    proposals[proposalId].vote.startBlock - 1
                );
        } else if (roles[0].contains(account)) {
            return
                getGovernanceToken().getPastTotalSupply(
                    proposals[proposalId].vote.startBlock - 1
                );
        }
        return 0;
    }

    /**
     * @dev Internal function to set the last proposal ID for an address.
     * @param proposer The proposer's address.
     * @param proposalId The proposal ID.
     */
    function _setLastProposalIdForAddress(
        address proposer,
        uint256 proposalId
    ) internal override {
        lastProposalIdForAddress[proposer] = proposalId;
    }
}
