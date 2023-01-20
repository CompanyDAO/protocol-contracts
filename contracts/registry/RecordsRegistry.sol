// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./RegistryBase.sol";
import "../interfaces/registry/IRecordsRegistry.sol";

abstract contract RecordsRegistry is RegistryBase, IRecordsRegistry {
    // STORAGE

    /// @dev List of contract records
    ContractInfo[] public contractRecords;

    struct ContractIndex {
        bool exists;
        uint160 index;
    }

    /// @dev Mapping of contract addresses to their record indexes
    mapping(address => ContractIndex) public indexOfContract;

    /// @dev List of proposal records
    ProposalInfo[] public proposalRecords;

    /// @dev List of event records
    Event[] public events;

    // EVENTS

    /**
     * @dev Event emitted on creation of contract record
     * @param index Record index
     * @param addr Contract address
     * @param contractType Contract type
     */
    event ContractRecordAdded(
        uint256 index,
        address addr,
        ContractType contractType
    );

    /**
     * @dev Event emitted on creation of proposal record
     * @param index Record index
     * @param pool Pool address
     * @param proposalId Proposal ID
     */
    event ProposalRecordAdded(uint256 index, address pool, uint256 proposalId);

    /**
     * @dev Event emitted on creation of event
     * @param index Record index
     * @param eventType Event type
     * @param pool Pool address
     * @param proposalId Proposal ID
     */
    event EventRecordAdded(
        uint256 index,
        EventType eventType,
        address pool,
        uint256 proposalId
    );

    // PUBLIC FUNCTIONS

    /**
     * @dev Add contract record
     * @param addr Contract address
     * @param contractType Contract type
     * @return index Record index
     */
    function addContractRecord(
        address addr,
        ContractType contractType,
        string memory description
    ) external onlyService returns (uint256 index) {
        // Add record
        contractRecords.push(
            ContractInfo({
                addr: addr,
                contractType: contractType,
                description: description
            })
        );
        index = contractRecords.length - 1;

        // Add mapping from contract address
        indexOfContract[addr] = ContractIndex({
            exists: true,
            index: uint160(index)
        });

        // Emit event
        emit ContractRecordAdded(index, addr, contractType);
    }

    /**
     * @dev Add proposal record
     * @param pool Pool address
     * @param proposalId Proposal ID
     * @return index Record index
     */
    function addProposalRecord(address pool, uint256 proposalId)
        external
        onlyService
        returns (uint256 index)
    {
        // Add record
        proposalRecords.push(
            ProposalInfo({pool: pool, proposalId: proposalId, description: ""})
        );
        index = proposalRecords.length - 1;

        // Emit event
        emit ProposalRecordAdded(index, pool, proposalId);
    }

    /**
     * @dev Add event record
     * @param pool Pool address
     * @param eventType Event type
     * @param proposalId Proposal ID
     * @param metaHash Hash value of event metadata
     * @return index Record index
     */
    function addEventRecord(
        address pool,
        EventType eventType,
        uint256 proposalId,
        string calldata metaHash
    ) external onlyService returns (uint256 index) {
        // Add record
        events.push(
            Event({
                eventType: eventType,
                pool: pool,
                proposalId: proposalId,
                metaHash: metaHash
            })
        );
        index = events.length - 1;

        // Emit event
        emit EventRecordAdded(index, eventType, pool, proposalId);
    }

    // PUBLIC VIEW FUNCTIONS

    /**
     * @notice Returns type of given contract
     * @param addr Address of contract
     * @return Contract type
     */
    function typeOf(address addr) external view returns (ContractType) {
        ContractIndex memory index = indexOfContract[addr];
        return
            index.exists
                ? contractRecords[index.index].contractType
                : ContractType.None;
    }
}
