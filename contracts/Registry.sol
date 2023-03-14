// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./registry/CompaniesRegistry.sol";
import "./registry/RecordsRegistry.sol";
import "./registry/TokensRegistry.sol";

/// @dev The repository of all user and business entities created by the protocol: companies to be implemented, contracts to be deployed, proposal created by shareholders.
contract Registry is CompaniesRegistry, RecordsRegistry, TokensRegistry {
    /// @dev Mapping of pool contracts and local proposal ids to their global ids
    mapping(address => mapping(uint256 => uint256)) public globalProposalIds;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Initializer
     */
    function initialize() public initializer {
        __RegistryBase_init();
    }

    // INTERNAL FUNCTIONS

    /**
     * @dev Update global proposal ID
     * @param pool Pool address
     * @param proposalId Local Proposal ID
     * @param globalProposalId Global Proposal ID
     */
    function setGlobalProposalId(
        address pool,
        uint256 proposalId,
        uint256 globalProposalId
    ) internal override {
        globalProposalIds[pool][proposalId] = globalProposalId;
    }

    // VIEW FUNCTIONS

    /**
     * @dev Return global proposal ID
     * @param pool Pool address
     * @param proposalId Proposal ID
     * @return Global proposal ID
     */
    function getGlobalProposalId(
        address pool,
        uint256 proposalId
    ) public view returns (uint256) {
        return globalProposalIds[pool][proposalId];
    }
}
