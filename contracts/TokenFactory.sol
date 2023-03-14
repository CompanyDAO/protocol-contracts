// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import "./interfaces/IService.sol";
import "./interfaces/ITokenFactory.sol";
import "./libraries/ExceptionsLibrary.sol";

contract TokenFactory is Initializable, ITokenFactory {
    // STORAGE

    /// @notice Service contract
    IService public service;

    // MODIFIERS

    modifier onlyTGEFactory() {
        require(
            msg.sender == address(service.tgeFactory()),
            ExceptionsLibrary.NOT_TGE_FACTORY
        );
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
        service = service_;
    }

    /**
     * @dev Create token contract
     * @return token Token contract
     */
    function createToken(
        address pool,
        IToken.TokenInfo memory info,
        address primaryTGE
    ) external onlyTGEFactory returns (IToken token) {
        // Create token contract
        token = IToken(address(new BeaconProxy(service.tokenBeacon(), "")));

        // Initialize token
        token.initialize(service, pool, info, primaryTGE);

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
