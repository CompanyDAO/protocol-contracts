// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import "./interfaces/IService.sol";
import "./interfaces/ITokenFactory.sol";
import "./libraries/ExceptionsLibrary.sol";

/**
 * @title TokenFactory
 * @dev A factory for token contracts, utilizing the Beacon Proxy pattern for creating new contracts. 
 * Each new contract is a "proxy" pointing to a "beacon" that stores the implementation logic.
 * This enables cheaper creation of new contracts and easier updating of all contracts at once.
 * The contract can also be upgraded, meaning the contract's logic can be replaced while retaining the same contract address and state variables.
 */
contract TokenFactory is Initializable, ITokenFactory {
    // STORAGE

    /**
     * @notice Service contract
     */
    IService public service;

    // MODIFIERS

    /**
     * @notice Modifier restricting function call to TGEFactory contract only
     * @dev Throws an exception if the caller is not the TGEFactory contract's address
     */
    modifier onlyTGEFactory() {
        require(
            msg.sender == address(service.tgeFactory()),
            ExceptionsLibrary.NOT_TGE_FACTORY
        );
        _;
    }

    // INITIALIZER

    /**
     * @notice Contract constructor
     * @dev Disables the usage of initializers
     */
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Initializer function, can only be called once
     * @param service_ Address of the service contract
     */
    function initialize(IService service_) external initializer {
        service = service_;
    }

    /**
     * @dev Creates a token contract
     * @param pool Address of the pool
     * @param info Token information
     * @param primaryTGE Address of the primary TGE
     * @return token Token contract
     */
    function createToken(
        address pool,
        IToken.TokenInfo memory info,
        address primaryTGE
    ) external onlyTGEFactory returns (address token) {
        // Create token contract
        token = address(new BeaconProxy(service.tokenBeacon(), ""));

        // Initialize token
        IToken(token).initialize(service, pool, info, primaryTGE);

        // Add token contract to registry
        service.registry().addContractRecord(
            address(token),
            IToken(token).tokenType() == IToken.TokenType.Governance
                ? IRecordsRegistry.ContractType.GovernanceToken
                : IRecordsRegistry.ContractType.PreferenceToken,
            ""
        );
    }

    /**
     * @dev Creates a ERC1155 token contract
     * @param pool Address of the pool
     * @param info Token information
     * @param primaryTGE Address of the primary TGE
     * @return token Token contract
     */
    function createTokenERC1155(
        address pool,
        IToken.TokenInfo memory info,
        address primaryTGE
    ) external onlyTGEFactory returns (address token) {
        // Create token contract
        token = address(new BeaconProxy(service.tokenERC1155Beacon(), ""));

        // Initialize token
        ITokenERC1155(token).initialize(service, pool, info, primaryTGE);

        // Add token contract to registry
        service.registry().addContractRecord(
            address(token),
            IToken(token).tokenType() == IToken.TokenType.Governance
                ? IRecordsRegistry.ContractType.GovernanceToken
                : IRecordsRegistry.ContractType.PreferenceToken,
            ""
        );
    }
}