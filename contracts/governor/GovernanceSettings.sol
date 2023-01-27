// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "../interfaces/registry/IRegistry.sol";
import "../interfaces/registry/IRecordsRegistry.sol";
import "../interfaces/governor/IGovernanceSettings.sol";
import "../libraries/ExceptionsLibrary.sol";

abstract contract GovernanceSettings is IGovernanceSettings {
    // CONSTANTS

    /// @notice Denominator for shares (such as thresholds)
    uint256 private constant DENOM = 100 * 10**4;

    /// @notice Max base execution delay (as blocks)
    uint256 public constant MAX_BASE_EXECUTION_DELAY = 20;

    // STORAGE

    /// @notice Threshold of votes required to propose
    uint256 public proposalThreshold;

    /// @notice Threshold of votes required to reach quorum
    uint256 public quorumThreshold;

    /// @notice Threshold of for votes required for proposal to succeed
    uint256 public decisionThreshold;

    /// @notice Duration of proposal voting (as blocks)
    uint256 public votingDuration;

    /// @notice Minimal transfer value to trigger delay
    uint256 public transferValueForDelay;

    /// @notice Delays for proposal types
    mapping(IRegistry.EventType => uint256) public executionDelays;

    /// @notice Storage gap (for future upgrades)
    uint256[50] private __gap;

    // EVENTS

    /// @notice Event emitted when governance settings are set
    event GovernanceSettingsSet(
        uint256 proposalThreshold_,
        uint256 quorumThreshold_,
        uint256 decisionThreshold_,
        uint256 votingDuration_,
        uint256 transferValueForDelay_,
        uint256[4] executionDelays_
    );

    // PUBLIC FUNCTIONS

    /**
     * @notice Updates governance settings
     * @param settings New governance settings
     */
    function setGovernanceSettings(NewGovernanceSettings memory settings)
        external
    {
        // Can only be called by self
        require(msg.sender == address(this), ExceptionsLibrary.INVALID_USER);

        // Update settings
        _setGovernanceSettings(settings);
    }

    // INTERNAL FUNCTIONS

    /**
     * @notice Updates governance settings
     * @param settings New governance settings
     */
    function _setGovernanceSettings(NewGovernanceSettings memory settings)
        internal
    {
        // Validate settings
        _validateGovernanceSettings(settings);

        // Apply settings
        proposalThreshold = settings.proposalThreshold;
        quorumThreshold = settings.quorumThreshold;
        decisionThreshold = settings.decisionThreshold;
        votingDuration = settings.votingDuration;
        transferValueForDelay = settings.transferValueForDelay;

        executionDelays[IRecordsRegistry.EventType.None] = settings
            .executionDelays[0];
        executionDelays[IRecordsRegistry.EventType.Transfer] = settings
            .executionDelays[1];
        executionDelays[IRecordsRegistry.EventType.TGE] = settings
            .executionDelays[2];
        executionDelays[
            IRecordsRegistry.EventType.GovernanceSettings
        ] = settings.executionDelays[3];
    }

    // INTERNAL VIEW FUNCTIONS

    /**
     * @notice Validates governance settings
     * @param settings New governance settings
     */
    function _validateGovernanceSettings(NewGovernanceSettings memory settings)
        internal
        pure
    {
        // Check all values for sanity
        require(
            settings.quorumThreshold < DENOM,
            ExceptionsLibrary.INVALID_VALUE
        );
        require(
            settings.decisionThreshold < DENOM,
            ExceptionsLibrary.INVALID_VALUE
        );
        require(settings.votingDuration > 0, ExceptionsLibrary.INVALID_VALUE);
    }
}
