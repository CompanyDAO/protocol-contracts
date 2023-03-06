// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./IToken.sol";
import "./registry/IRegistry.sol";
import "./governor/IGovernor.sol";
import "./governor/IGovernanceSettings.sol";
import "./governor/IGovernorProposals.sol";

interface IPool is IGovernorProposals {
    function initialize(
        address owner_,
        string memory trademark_,
        IGovernanceSettings.NewGovernanceSettings memory governanceSettings_,
        IRegistry.CompanyInfo memory companyInfo_
    ) external;

    function propose(
        address proposer,
        uint256 proposalType,
        IGovernor.ProposalCoreData memory core,
        IGovernor.ProposalMetaData memory meta
    ) external returns (uint256 proposalId);

    function setToken(address token_, IToken.TokenType tokenType_) external;

    function setProposalIdToTGE(address tge) external;

    function cancelProposal(uint256 proposalId) external;

    function changePoolSecretary(
        address[] memory addSecretary,
        address[] memory removeSecretary
    ) external;

    function owner() external view returns (address);

    function isDAO() external view returns (bool);

    function trademark() external view returns (string memory);

    function paused() external view returns (bool);

    function getGovernanceToken() external view returns (IToken);

    function tokenExists(IToken token_) external view returns (bool);

    function isValidProposer(address account) external view returns (bool);

    function isLastProposalIdByTypeActive(
        uint256 type_
    ) external view returns (bool);

    function validateGovernanceSettings(
        IGovernanceSettings.NewGovernanceSettings memory settings
    ) external pure;
}
