// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./RegistryBase.sol";
import "../interfaces/registry/IRecordsRegistry.sol";

abstract contract RecordsRegistry is RegistryBase, IRecordsRegistry {
    // STORAGE

    /// @dev In this array, records are stored about all contracts created by users (that is, about those generated by the service), namely, its index, with which you can extract all available information from other getters.
    ContractInfo[] public contractRecords;

    struct ContractIndex {
        bool exists;
        uint160 index;
    }

    /// @dev Mapping of contract addresses to their record indexes
    mapping(address => ContractIndex) public indexOfContract;

    /// @dev List of proposal records
    ProposalInfo[] public proposalRecords;

    /// @dev A list of existing events. An event can be either a contract or a specific action performed by a pool based on the results of voting for a promotion (for example, the transfer of funds from a pool contract is considered an event, but does not have a contract, and TGE has both the status of an event and its own separate contract).
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
     * @dev This method is used by the main Service contract in order to save the data of the contracts it deploys. After the Registry contract receives the address and type of the created contract from the Service contract, it sends back as a response the sequence number/index assigned to the new record.
     * @param addr Contract address
     * @param contractType Contract type
     * @return index Record index
     */
    function addContractRecord(
        address addr,
        ContractType contractType,
        string memory description
    ) external onlyServiceOrFactory returns (uint256 index) {
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
     * @dev This method accepts data from the Service contract about the created nodes in the pools. If there is an internal index of the proposal in the contract of the pool whose shareholders created the proposal, then as a result of using this method, the proposal is given a global index for the entire ecosystem.
     * @param pool Pool address
     * @param proposalId Proposal ID
     * @return index Record index
     */
    function addProposalRecord(
        address pool,
        uint256 proposalId
    ) external onlyService returns (uint256 index) {
        // Add record
        proposalRecords.push(
            ProposalInfo({pool: pool, proposalId: proposalId, description: ""})
        );
        index = proposalRecords.length - 1;
        setGlobalProposalId(pool, proposalId, index);
        // Emit event
        emit ProposalRecordAdded(index, pool, proposalId);
    }

    /**
     * @dev This method is used to register events - specific entities associated with the operational activities of pools and the transfer of various values as a result of the use of ecosystem contracts. Each event also has a metahash string field, which is the identifier of the private description of the event stored on the backend.
     * @param pool Pool address
     * @param eventType Event type
     * @param eventContract Address of the event contract
     * @param proposalId Proposal ID
     * @param metaHash Hash value of event metadata
     * @return index Record index
     */
    function addEventRecord(
        address pool,
        EventType eventType,
        address eventContract,
        uint256 proposalId,
        string calldata metaHash
    ) external onlyServiceOrFactory returns (uint256 index) {
        // Add record
        events.push(
            Event({
                eventType: eventType,
                pool: pool,
                eventContract: eventContract,
                proposalId: proposalId,
                metaHash: metaHash
            })
        );
        index = events.length - 1;

        // Emit event
        emit EventRecordAdded(index, eventType, pool, proposalId);
    }

    // VIRTUAL FUNCTIONS

    function setGlobalProposalId(
        address pool,
        uint256 proposalId,
        uint256 globalProposalId
    ) internal virtual;

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

    /**
     * @notice Returns number of contract records
     * @return Contract records count
     */
    function contractRecordsCount() external view returns (uint256) {
        return contractRecords.length;
    }

    /**
     * @notice Returns number of proposal records
     * @return Proposal records count
     */
    function proposalRecordsCount() external view returns (uint256) {
        return proposalRecords.length;
    }

    /**
     * @notice Returns number of event records
     * @return Event records count
     */
    function eventRecordsCount() external view returns (uint256) {
        return events.length;
    }
}
