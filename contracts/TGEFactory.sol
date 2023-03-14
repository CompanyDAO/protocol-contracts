// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import "./interfaces/IService.sol";
import "./interfaces/IToken.sol";
import "./interfaces/ITGE.sol";
import "./interfaces/IPool.sol";
import "./interfaces/ITGEFactory.sol";
import "./libraries/ExceptionsLibrary.sol";

contract TGEFactory is ReentrancyGuardUpgradeable, ITGEFactory {
    // STORAGE

    /// @notice Service contract
    IService public service;

    // EVENTS

    /**
     * @dev Event emitted on creation of primary TGE.
     * @param pool Pool address
     * @param tge Secondary TGE address
     * @param token Preference token address
     */
    event PrimaryTGECreated(address pool, address tge, address token);

    /**
     * @dev Event emitted on creation of secondary TGE.
     * @param pool Pool address
     * @param tge Secondary TGE address
     * @param token Preference token address
     */
    event SecondaryTGECreated(address pool, address tge, address token);

    // MODIFIERS

    modifier onlyPool() {
        require(
            service.registry().typeOf(msg.sender) ==
                IRecordsRegistry.ContractType.Pool,
            ExceptionsLibrary.NOT_POOL
        );
        _;
    }

    modifier whenNotPaused() {
        require(!service.paused(), ExceptionsLibrary.SERVICE_PAUSED);
        _;
    }

    // INITIALIZER

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Initializer function, can only be called once
     * @param service_ Service address
     */
    function initialize(IService service_) external initializer {
        __ReentrancyGuard_init();
        service = service_;
    }

    // EXTERNAL FUNCTIONS

    /**
     * @dev Method for launching primary TGE for tokens
     * @param poolAddress Pool address.
     * @param tokenInfo New token parameters (token type, decimals & description are ignored)
     * @param tgeInfo Pool TGE parameters
     * @param metadataURI Metadata URI
     */
    function createPrimaryTGE(
        address poolAddress,
        IToken.TokenInfo memory tokenInfo,
        ITGE.TGEInfo memory tgeInfo,
        string memory metadataURI
    ) external nonReentrant whenNotPaused {
        // Check that sender is pool owner
        IPool pool = IPool(poolAddress);
        require(pool.owner() == msg.sender, ExceptionsLibrary.NOT_POOL_OWNER);

        // Check token cap
        require(tokenInfo.cap >= 1 ether, ExceptionsLibrary.INVALID_CAP);

        // Check that pool is not active yet
        require(
            address(pool.getGovernanceToken()) == address(0) || !pool.isDAO(),
            ExceptionsLibrary.GOVERNANCE_TOKEN_EXISTS
        );

        // Add protocol fee to token cap
        tokenInfo.cap += service.getProtocolTokenFee(tokenInfo.cap);

        // Create TGE contract
        ITGE tge = _createTGE(metadataURI, address(pool));

        // Create token contract
        tokenInfo.tokenType = IToken.TokenType.Governance;
        tokenInfo.decimals = 18;
        IToken token = service.tokenFactory().createToken(
            address(pool),
            tokenInfo,
            address(tge)
        );

        // Set token as pool token
        pool.setToken(address(token), IToken.TokenType.Governance);

        // Initialize TGE
        tge.initialize(
            address(service),
            token,
            tgeInfo,
            service.protocolTokenFee()
        );
        emit PrimaryTGECreated(address(pool), address(tge), address(token));
    }

    /**
     * @dev Method for launching secondary TGE (i.e. without reissuing the token) for Governance tokens, as well as for creating and launching TGE for Preference tokens. It can be started only as a result of the execution of the proposal on behalf of the pool.
     * @param tgeInfo TGE parameters
     * @param tokenInfo Token parameters
     * @param metadataURI Metadata URI
     */
    function createSecondaryTGE(
        IToken token,
        ITGE.TGEInfo calldata tgeInfo,
        IToken.TokenInfo calldata tokenInfo,
        string memory metadataURI
    ) external onlyPool nonReentrant whenNotPaused {
        ITGE tge;
        // Check whether it's initial preference TGE or any secondary token
        if (
            tokenInfo.tokenType == IToken.TokenType.Preference &&
            address(token) == address(0)
        ) {
            (token, tge) = _createInitialPreferenceTGE(
                token,
                tgeInfo,
                tokenInfo,
                metadataURI
            );
        } else {
            (token, tge) = _createSecondaryTGE(
                token,
                tgeInfo,
                tokenInfo,
                metadataURI
            );
        }

        // Add proposal id to TGE
        IPool(msg.sender).setProposalIdToTGE(address(tge));

        // Emit event
        emit SecondaryTGECreated(msg.sender, address(tge), address(token));
    }

    // INTERNAL FUNCTIONS

    function _createSecondaryTGE(
        IToken token,
        ITGE.TGEInfo calldata tgeInfo,
        IToken.TokenInfo calldata tokenInfo,
        string memory metadataURI
    ) internal returns (IToken, ITGE) {
        // Check that token is valid
        require(
            tokenInfo.tokenType != IToken.TokenType.None &&
                IPool(msg.sender).tokenTypeByAddress(address(token)) ==
                tokenInfo.tokenType,
            ExceptionsLibrary.WRONG_TOKEN_ADDRESS
        );

        // Check that there is no active TGE
        require(
            ITGE(token.lastTGE()).state() != ITGE.State.Active,
            ExceptionsLibrary.ACTIVE_TGE_EXISTS
        );

        // Create TGE
        ITGE tge = _createTGE(metadataURI, msg.sender);

        // Add TGE to token's list
        token.addTGE(address(tge));

        // Get protocol fee
        uint256 protocolTokenFee = tokenInfo.tokenType ==
            IToken.TokenType.Governance
            ? service.protocolTokenFee()
            : 0;

        // Initialize TGE
        tge.initialize(address(service), token, tgeInfo, protocolTokenFee);

        return (token, tge);
    }

    function _createInitialPreferenceTGE(
        IToken token,
        ITGE.TGEInfo calldata tgeInfo,
        IToken.TokenInfo calldata tokenInfo,
        string memory metadataURI
    ) internal returns (IToken, ITGE) {
        // Create TGE
        ITGE tge = _createTGE(metadataURI, msg.sender);

        // Create token contract
        token = service.tokenFactory().createToken(
            msg.sender,
            tokenInfo,
            address(tge)
        );

        // Add token to Pool
        IPool(msg.sender).setToken(address(token), IToken.TokenType.Preference);

        // Initialize TGE
        tge.initialize(address(service), token, tgeInfo, 0);

        return (token, tge);
    }

    /**
     * @dev Create TGE contract
     * @param metadataURI TGE metadata URI
     * @param pool Pool address
     * @return tge TGE contract
     */
    function _createTGE(
        string memory metadataURI,
        address pool
    ) internal returns (ITGE tge) {
        // Create TGE contract
        tge = ITGE(address(new BeaconProxy(service.tgeBeacon(), "")));

        // Add TGE contract to registry
        service.registry().addContractRecord(
            address(tge),
            IRecordsRegistry.ContractType.TGE,
            metadataURI
        );

        // Add TGE event to registry
        service.registry().addEventRecord(
            pool,
            IRecordsRegistry.EventType.TGE,
            address(tge),
            0,
            ""
        );
    }
}
