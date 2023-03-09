// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import "@openzeppelin/contracts-upgradeable/utils/Create2Upgradeable.sol";
import "./interfaces/IService.sol";
import "./interfaces/IPool.sol";
import "./interfaces/IToken.sol";
import "./interfaces/ITGE.sol";
import "./interfaces/IVesting.sol";
import "./interfaces/registry/IRegistry.sol";
import "./interfaces/ICustomProposal.sol";
import "./interfaces/registry/IRecordsRegistry.sol";
import "./libraries/ExceptionsLibrary.sol";

/// @dev The main service contract through which the administrator manages the project, assigns roles to individual wallets, changes service commissions, and also through which the user creates pool contracts. Exists in a single copy.
contract Service is
    Initializable,
    AccessControlEnumerableUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable,
    IService
{
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using AddressUpgradeable for address;

    // CONSTANTS

    /// @notice Denominator for shares (such as thresholds)
    uint256 private constant DENOM = 100 * 10**4;

    /// @notice Default admin  role
    bytes32 public constant ADMIN_ROLE = DEFAULT_ADMIN_ROLE;

    /// @notice User manager role
    bytes32 public constant SERVICE_MANAGER_ROLE = keccak256("USER_MANAGER");

    /// @notice User role
    bytes32 public constant WHITELISTED_USER_ROLE =
        keccak256("WHITELISTED_USER");

    /// @notice Executor role
    bytes32 public constant EXECUTOR_ROLE = keccak256("EXECUTOR");

    // STORAGE

    /// @dev Registry contract
    IRegistry public registry;

    /// @dev Pool beacon
    address public poolBeacon;

    /// @dev Token beacon
    address public tokenBeacon;

    /// @dev TGE beacon
    address public tgeBeacon;

    /// @dev There gets 0.1% (the value can be changed by the admin) of all Governance tokens from successful TGE
    address public protocolTreasury;

    /// @dev protocol token fee percentage value with 4 decimals. Examples: 1% = 10000, 100% = 1000000, 0.1% = 1000
    uint256 public protocolTokenFee;

    /// @dev protocol token fee claimed for tokens
    mapping(address => uint256) public protolCollectedFee;

    /// @dev Proposal beacon
    ICustomProposal public customProposal;

    /// @dev Vesting contract
    IVesting public vesting;
    // EVENTS

    /**
     * @dev Event emitted on pool creation.
     * @param pool Pool address
     * @param token Pool token address
     * @param tge Pool primary TGE address
     */
    event PoolCreated(address pool, address token, address tge);

    /**
     * @dev Event that emits when a pool is purchased.
     * @param pool Pool address
     * @param token Pool token address
     * @param tge Pool primary TGE address
     */
    event PoolPurchased(address pool, address token, address tge);

    /**
     * @dev Event emitted on creation of secondary TGE.
     * @param pool Pool address
     * @param tge Secondary TGE address
     * @param token Preference token address
     */
    event SecondaryTGECreated(address pool, address tge, address token);

    /**
     * @dev Event emitted on protocol treasury change.
     * @param protocolTreasury Protocol treasury address
     */
    event ProtocolTreasuryChanged(address protocolTreasury);

    /**
     * @dev Event emitted on protocol token fee change.
     * @param protocolTokenFee Protocol token fee
     */
    event ProtocolTokenFeeChanged(uint256 protocolTokenFee);

    /**
     * @dev Event emitted on transferring collected fees.
     * @param to Transfer recepient
     * @param amount Amount of transferred ETH
     */
    event FeesTransferred(address to, uint256 amount);

    /**
     * @dev Event emitted on proposal cacellation by service owner.
     * @param pool Pool address
     * @param proposalId Pool local proposal id
     */
    event ProposalCancelled(address pool, uint256 proposalId);

    // MODIFIERS

    modifier onlyPool() {
        require(
            registry.typeOf(msg.sender) == IRecordsRegistry.ContractType.Pool,
            ExceptionsLibrary.NOT_POOL
        );
        _;
    }

    modifier onlyTGE() {
        require(
            registry.typeOf(msg.sender) == IRecordsRegistry.ContractType.TGE,
            ExceptionsLibrary.NOT_TGE
        );
        _;
    }

    modifier onlyRegistry() {
        require(
            msg.sender == address(registry),
            ExceptionsLibrary.NOT_REGISTRY
        );
        _;
    }

    // INITIALIZER AND CONSTRUCTOR

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Initializer function, can only be called once
     * @param registry_ Registry address
     * @param customProposal_ Custom proposals address
     * @param vesting_ Vesting address
     * @param poolBeacon_ Pool beacon
     * @param tokenBeacon_ Governance token beacon
     * @param tgeBeacon_ TGE beacon
     * @param protocolTokenFee_ Protocol token fee
     */
    function initialize(
        IRegistry registry_,
        ICustomProposal customProposal_,
        IVesting vesting_,
        address poolBeacon_,
        address tokenBeacon_,
        address tgeBeacon_,
        uint256 protocolTokenFee_
    ) external reinitializer(2) {
        require(
            address(registry_) != address(0),
            ExceptionsLibrary.ADDRESS_ZERO
        );
        require(poolBeacon_ != address(0), ExceptionsLibrary.ADDRESS_ZERO);
        require(tokenBeacon_ != address(0), ExceptionsLibrary.ADDRESS_ZERO);
        require(tgeBeacon_ != address(0), ExceptionsLibrary.ADDRESS_ZERO);
        __Pausable_init();
        __ReentrancyGuard_init();

        registry = registry_;
        vesting = vesting_;
        poolBeacon = poolBeacon_;
        tokenBeacon = tokenBeacon_;
        tgeBeacon = tgeBeacon_;
        customProposal = customProposal_;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(SERVICE_MANAGER_ROLE, msg.sender);
        _grantRole(EXECUTOR_ROLE, msg.sender);
        _setRoleAdmin(WHITELISTED_USER_ROLE, SERVICE_MANAGER_ROLE);

        setProtocolTreasury(address(this));
        setProtocolTokenFee(protocolTokenFee_);
    }

    // PUBLIC FUNCTIONS

    /**
     * @dev Method for purchasing a pool by the user. Among the data submitted for input, there are jurisdiction and Entity Type
     * @param jurisdiction jurisdiction
     * @param entityType entityType
     */
    function purchasePool(
        uint256 jurisdiction,
        uint256 entityType,
        string memory trademark,
        IGovernanceSettings.NewGovernanceSettings memory governanceSettings
    )
        external
        payable
        onlyRole(WHITELISTED_USER_ROLE)
        nonReentrant
        whenNotPaused
    {
        // Lock company
        IRegistry.CompanyInfo memory companyInfo = registry.lockCompany(
            jurisdiction,
            entityType
        );

        // Check fee
        require(
            msg.value == companyInfo.fee,
            ExceptionsLibrary.INCORRECT_ETH_PASSED
        );

        // Create pool
        IPool pool = IPool(getPoolAddress(companyInfo));

        // setNewOwnerWithSettings to pool contract
        pool.setNewOwnerWithSettings(msg.sender, trademark, governanceSettings);

        // Emit event
        emit PoolPurchased(address(pool), address(0), address(0));
    }

    // PUBLIC INDIRECT FUNCTIONS (CALLED THROUGH POOL OR REGISTRY)

    /**
     * @dev Method for launching secondary TGE (i.e. without reissuing the token) for Governance tokens, as well as for creating and launching TGE for Preference tokens. It can be started only as a result of the execution of the proposal on behalf of the pool.
     * @param tgeInfo TGE parameters
     * @param tokenInfo Token parameters
     * @param metadataURI Metadata URI
     */
    function createSecondaryTGE(
        IToken token,
        ITGE.TGEInfoV2 calldata tgeInfo,
        IToken.TokenInfo calldata tokenInfo,
        string memory metadataURI
    ) external onlyPool nonReentrant whenNotPaused {
        // Create TGE
        ITGE tge = _createTGE(metadataURI, msg.sender);

        // Check for token type (Governance or Preference)
        if (tokenInfo.tokenType == IToken.TokenType.Governance) {
            // Case of Governance token

            require(
                IPool(msg.sender).getGovernanceToken() == token,
                ExceptionsLibrary.WRONG_TOKEN_ADDRESS
            );

            // Check that there is no active TGE
            require(
                ITGE(token.lastTGE()).state() != ITGE.State.Active,
                ExceptionsLibrary.ACTIVE_TGE_EXISTS
            );

            // Add TGE to token's list
            token.addTGE(address(tge));

            // Initialize TGE
            tge.initialize(token, tgeInfo, protocolTokenFee);
        } else if (tokenInfo.tokenType == IToken.TokenType.Preference) {
            // Case of Preference token

            // Check if it's new token or additional TGE
            if (address(token) == address(0)) {
                // Create token contract
                token = _createToken();

                // Initialize token contract
                token.initialize(msg.sender, tokenInfo, address(tge));

                // Add token to Pool
                IPool(msg.sender).setToken(
                    address(token),
                    IToken.TokenType.Preference
                );

                // Initialize TGE
                tge.initialize(token, tgeInfo, 0);
            } else {
                // Check if  token exists for Pool
                require(
                    IPool(msg.sender).tokenExists(token),
                    ExceptionsLibrary.WRONG_TOKEN_ADDRESS
                );
                // Check that there is no active TGE
                require(
                    ITGE(token.lastTGE()).state() != ITGE.State.Active,
                    ExceptionsLibrary.ACTIVE_TGE_EXISTS
                );

                // Add TGE to token's list
                token.addTGE(address(tge));

                // Initialize TGE
                tge.initialize(token, tgeInfo, 0);
            }
        } else {
            // Revert for unsupported token types
            revert(ExceptionsLibrary.UNSUPPORTED_TOKEN_TYPE);
        }

        IPool(msg.sender).setProposalIdToTGE(address(tge));
        // Emit event
        emit SecondaryTGECreated(msg.sender, address(tge), address(token));
    }

    /**
     * @dev Add proposal to directory
     * @param proposalId Proposal ID
     */
    function addProposal(uint256 proposalId) external onlyPool whenNotPaused {
        registry.addProposalRecord(msg.sender, proposalId);
    }

    /**
     * @dev Add event to directory
     * @param eventType Event type
     * @param proposalId Proposal ID
     * @param metaHash Hash value of event metadata
     */
    function addEvent(
        IRegistry.EventType eventType,
        uint256 proposalId,
        string calldata metaHash
    ) external onlyPool whenNotPaused {
        registry.addEventRecord(
            msg.sender,
            eventType,
            address(0),
            proposalId,
            metaHash
        );
    }

    /**
     * @dev Method for purchasing a pool by the user. Among the data submitted for input, there are jurisdiction and Entity Type, which are used as keys to, firstly, find out if there is a company available for acquisition with such parameters among the Registry records, and secondly, to get the data of such a company if it exists, save them to the deployed pool contract, while recording the company is removed from the Registry. This action is only available to users who are on the global white list of addresses allowed before the acquisition of companies. At the same time, the Governance token contract and the TGE contract are deployed for its implementation.
     * @param companyInfo Company info
     */
    function createPool(IRegistry.CompanyInfo memory companyInfo)
        external
        onlyRegistry
        nonReentrant
        whenNotPaused
    {
        // Create pool
        IPool pool = _createPool(companyInfo);

        // Initialize pool contract
        pool.initialize(companyInfo);

        // Emit event
        emit PoolCreated(address(pool), address(0), address(0));
    }

    // RESTRICTED FUNCTIONS

    /**
     * @dev Method for launching primary TGE  for Governance tokens
     * @param pool_address Pool address.
     * @param tokenCap Pool token cap
     * @param tokenName Pool token name
     * @param tokenSymbol Pool token symbol
     * @param tgeInfo Pool TGE parameters
     * @param metadataURI Metadata URI
     */
    function createPrimaryTGE(
        address pool_address,
        uint256 tokenCap,
        string memory tokenName,
        string memory tokenSymbol,
        ITGE.TGEInfoV2 memory tgeInfo,
        string memory metadataURI
    ) external nonReentrant whenNotPaused {
        IPool pool = IPool(pool_address);

        require(pool.owner() == msg.sender, ExceptionsLibrary.NOT_POOL_OWNER);
        // Check token cap
        require(tokenCap >= 1 ether, ExceptionsLibrary.INVALID_CAP);

        // Check that pool is not active yet
        require(
            address(pool.getGovernanceToken()) == address(0) || !pool.isDAO(),
            ExceptionsLibrary.GOVERNANCE_TOKEN_EXISTS
        );

        // Add protocol fee to token cap
        tokenCap += getProtocolTokenFee(tokenCap);

        // Create token contract
        IToken token = _createToken();

        // Create TGE contract
        ITGE tge = _createTGE(metadataURI, address(pool));

        // Initialize token
        token.initialize(
            address(pool),
            IToken.TokenInfo({
                tokenType: IToken.TokenType.Governance,
                name: tokenName,
                symbol: tokenSymbol,
                description: "",
                cap: tokenCap,
                decimals: 18
            }),
            address(tge)
        );

        // Set token as pool token
        pool.setToken(address(token), IToken.TokenType.Governance);

        // Initialize TGE
        tge.initialize(token, tgeInfo, protocolTokenFee);
    }

    /**
     * @dev Transfer collected createPool protocol fees
     * @param to Transfer recipient
     */
    function transferCollectedFees(address to)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(to != address(0), ExceptionsLibrary.ADDRESS_ZERO);
        uint256 balance = payable(address(this)).balance;
        (bool success, ) = payable(to).call{value: balance}("");
        require(success, ExceptionsLibrary.EXECUTION_FAILED);
        emit FeesTransferred(to, balance);
    }

    /**
     * @dev Set protocol collected token fee
     * @param _token token address
     * @param _protocolTokenFee fee collected
     */
    function setProtocolCollectedFee(address _token, uint256 _protocolTokenFee)
        public
        onlyTGE
    {
        protolCollectedFee[_token] += _protocolTokenFee;
    }

    /**
     * @dev Assignment of the address to which the commission will be collected in the form of Governance tokens issued under successful TGE
     * @param _protocolTreasury Protocol treasury address
     */
    function setProtocolTreasury(address _protocolTreasury)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(
            _protocolTreasury != address(0),
            ExceptionsLibrary.ADDRESS_ZERO
        );

        protocolTreasury = _protocolTreasury;
        emit ProtocolTreasuryChanged(protocolTreasury);
    }

    /**
     * @dev Set protocol token fee
     * @param _protocolTokenFee protocol token fee percentage value with 4 decimals.
     * Examples: 1% = 10000, 100% = 1000000, 0.1% = 1000.
     */
    function setProtocolTokenFee(uint256 _protocolTokenFee)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(_protocolTokenFee <= DENOM, ExceptionsLibrary.INVALID_VALUE);

        protocolTokenFee = _protocolTokenFee;
        emit ProtocolTokenFeeChanged(_protocolTokenFee);
    }

    /**
     * @dev Sets new Registry contract
     * @param _registry registry address
     */
    function setRegistry(IRegistry _registry)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(
            address(_registry) != address(0),
            ExceptionsLibrary.ADDRESS_ZERO
        );

        registry = _registry;
    }

    /**
     * @dev Sets new customProposal contract
     * @param _customProposal customProposal address
     */
    function setCustomProposal(ICustomProposal _customProposal)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(
            address(_customProposal) != address(0),
            ExceptionsLibrary.ADDRESS_ZERO
        );

        customProposal = _customProposal;
    }

    /**
     * @dev Sets new vesting
     * @param _vesting vesting address
     */
    function setVesting(IVesting _vesting)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(
            address(_vesting) != address(0),
            ExceptionsLibrary.ADDRESS_ZERO
        );

        vesting = _vesting;
    }

    /**
     * @dev Sets new pool beacon
     * @param beacon Beacon address
     */
    function setPoolBeacon(address beacon)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(beacon != address(0), ExceptionsLibrary.ADDRESS_ZERO);

        poolBeacon = beacon;
    }

    /**
     * @dev Sets new token beacon
     * @param beacon Beacon address
     */
    function setTokenBeacon(address beacon)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(beacon != address(0), ExceptionsLibrary.ADDRESS_ZERO);

        tokenBeacon = beacon;
    }

    /**
     * @dev Sets new TGE beacon
     * @param beacon Beacon address
     */
    function setTGEBeacon(address beacon)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(beacon != address(0), ExceptionsLibrary.ADDRESS_ZERO);

        tgeBeacon = beacon;
    }

    /**
     * @dev Cancel pool's proposal
     * @param pool pool
     * @param proposalId proposalId
     */
    function cancelProposal(address pool, uint256 proposalId)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        IPool(pool).cancelProposal(proposalId);
        emit ProposalCancelled(pool, proposalId);
    }

    /**
     * @dev Pause service
     */
    function pause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    /**
     * @dev Unpause service
     */
    function unpause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    // PUBLIC VIEW FUNCTIONS

    /**
     * @dev Calculate minimum soft cap for token fee mechanism to work
     * @return softCap minimum soft cap
     */
    function getMinSoftCap() public view returns (uint256) {
        return (DENOM + protocolTokenFee - 1) / protocolTokenFee;
    }

    /**
     * @dev Сalculates protocol token fee for given token amount
     * @param amount Token amount
     * @return tokenFee
     */
    function getProtocolTokenFee(uint256 amount) public view returns (uint256) {
        require(amount >= getMinSoftCap(), ExceptionsLibrary.INVALID_VALUE);
        return (amount * protocolTokenFee + (DENOM - 1)) / DENOM;
    }

    /**
     * @dev Returns protocol token fee claimed for given token
     * @param token_ Token adress
     * @return token claimed
     */
    function getProtocolCollectedFee(address token_)
        external
        view
        returns (uint256)
    {
        return protolCollectedFee[token_];
    }

    /**
     * @dev Return max hard cap accounting for protocol token fee
     * @param _pool pool to calculate hard cap against
     * @return Maximum hard cap
     */
    function getMaxHardCap(address _pool) public view returns (uint256) {
        if (
            registry.typeOf(_pool) == IRecordsRegistry.ContractType.Pool &&
            IPool(_pool).isDAO()
        ) {
            return
                IPool(_pool).getGovernanceToken().cap() -
                getProtocolTokenFee(IPool(_pool).getGovernanceToken().cap());
        }

        return type(uint256).max - getProtocolTokenFee(type(uint256).max);
    }

    /// @dev Service function that is used to check the correctness of TGE parameters (for the absence of conflicts between parameters)
    function validateTGEInfo(
        ITGE.TGEInfoV2 calldata info,
        uint256 cap,
        uint256 totalSupplyWithReserves,
        IToken.TokenType tokenType
    ) external view {
        // Check unit of account
        if (info.unitOfAccount != address(0))
            require(
                IERC20Upgradeable(info.unitOfAccount).totalSupply() > 0,
                ExceptionsLibrary.INVALID_TOKEN
            );

        // Check hardcap
        require(
            info.hardcap >= info.softcap,
            ExceptionsLibrary.INVALID_HARDCAP
        );

        // Check vesting params
        vesting.validateParams(info.vestingParams);

        // Check remaining supply
        uint256 remainingSupply = cap - totalSupplyWithReserves;
        require(
            info.hardcap <= remainingSupply,
            ExceptionsLibrary.HARDCAP_OVERFLOW_REMAINING_SUPPLY
        );
        if (tokenType == IToken.TokenType.Governance) {
            require(
                info.hardcap + getProtocolTokenFee(info.hardcap) <=
                    remainingSupply,
                ExceptionsLibrary
                    .HARDCAP_AND_PROTOCOL_FEE_OVERFLOW_REMAINING_SUPPLY
            );
        }
    }

    /**
     * @dev Get's create2 address for pool
     * @param info Company info
     * @return Pool contract address
     */
    function getPoolAddress(IRegistry.CompanyInfo memory info)
        public
        view
        returns (address)
    {
        (bytes32 salt, bytes memory bytecode) = _getCreate2Data(info);
        return Create2Upgradeable.computeAddress(salt, keccak256(bytecode));
    }

    // INTERNAL FUNCTIONS

    /**
     * @dev Gets data for pool's create2
     * @param info Company info
     * @return salt Create2 salt
     * @return deployBytecode Deployed bytecode
     */
    function _getCreate2Data(IRegistry.CompanyInfo memory info)
        internal
        view
        returns (bytes32 salt, bytes memory deployBytecode)
    {
        // Get salt
        salt = keccak256(
            abi.encode(info.jurisdiction, info.entityType, info.ein)
        );

        // Get bytecode
        bytes memory proxyBytecode = type(BeaconProxy).creationCode;
        deployBytecode = abi.encodePacked(
            proxyBytecode,
            abi.encode(poolBeacon, "")
        );
    }

    /**
     * @dev Create pool contract and initialize it
     * @return pool Pool contract
     */
    function _createPool(IRegistry.CompanyInfo memory info)
        internal
        returns (IPool pool)
    {
        // Create pool contract using Create2
        (bytes32 salt, bytes memory bytecode) = _getCreate2Data(info);
        pool = IPool(Create2Upgradeable.deploy(0, salt, bytecode));

        // Add pool contract to registry
        registry.addContractRecord(
            address(pool),
            IRecordsRegistry.ContractType.Pool,
            ""
        );
    }

    /**
     * @dev Create token contract
     * @return token Token contract
     */
    function _createToken() internal returns (IToken token) {
        // Create token contract
        token = IToken(address(new BeaconProxy(tokenBeacon, "")));

        // Add token contract to registry
        registry.addContractRecord(
            address(token),
            IToken(token).tokenType() == IToken.TokenType.Governance
                ? IRecordsRegistry.ContractType.GovernanceToken
                : IRecordsRegistry.ContractType.PreferenceToken,
            ""
        );
    }

    /**
     * @dev Create TGE contract
     * @param metadataURI TGE metadata URI
     * @param pool Pool address
     * @return tge TGE contract
     */
    function _createTGE(string memory metadataURI, address pool)
        internal
        returns (ITGE tge)
    {
        // Create TGE contract
        tge = ITGE(address(new BeaconProxy(tgeBeacon, "")));

        // Add TGE contract to registry
        registry.addContractRecord(
            address(tge),
            IRecordsRegistry.ContractType.TGE,
            metadataURI
        );

        // Add TGE event to registry
        registry.addEventRecord(
            pool,
            IRecordsRegistry.EventType.TGE,
            address(tge),
            0,
            ""
        );
    }
}
