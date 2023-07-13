// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "./Governor.sol";
import "./GovernanceSettings.sol";
import "../interfaces/IPool.sol";
import "../interfaces/governor/IGovernorProposals.sol";
import "../interfaces/IService.sol";
import "../interfaces/registry/IRecordsRegistry.sol";
import "../interfaces/ITGE.sol";
import "../interfaces/IToken.sol";
import "../interfaces/ICustomProposal.sol";
import "../libraries/ExceptionsLibrary.sol";
/**
* @title Governor Proposals Contract
* @notice Contract for tracking and typing the created proposals.
* @dev The final implementation of the voting logic is placed in this module, which inherits from the Governor contract and is inherited by pool contracts.
*/
abstract contract GovernorProposals is
    Initializable,
    Governor,
    GovernanceSettings,
    IGovernorProposals
{
    // STORAGE

    /// @dev The address of the Service contract.
    IService public service;

    /// @dev last Proposal Id By Type for state checking
    mapping(uint256 => uint256) public lastProposalIdByType;

    /// @notice Numerical codes to determine the type of proposals being created.
    /// @dev The code describes the nature and degree of impact on the pool of a set of transactions that should be executed as a result of a successful vote.
    enum ProposalType {
        Transfer,
        TGE,
        GovernanceSettings
        // 3 - PoolSecretary
        // 4 - CustomTx
        // 5 - PoolExecutor
        // 6 - proposeTGEERC1155
    }

    /// @notice Storage gap (for future upgrades)
    uint256[49] private __gap;
}
