// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./RegistryBase.sol";
import "../libraries/ExceptionsLibrary.sol";
import "../interfaces/registry/ICompaniesRegistry.sol";

abstract contract CompaniesRegistry is RegistryBase, ICompaniesRegistry {
    // CONSTANTS

    /// @dev Companies manager role
    bytes32 public constant COMPANIES_MANAGER_ROLE =
        keccak256("COMPANIES_MANAGER");

    // STORAGE

    /// @dev Company (list indexes) queues indexed by [jurisdiction][entityType]
    mapping(uint256 => mapping(uint256 => uint256[])) public queue;

    /// @dev Companies
    mapping(uint256 => CompanyInfo) public companies;

    /// @dev Last company index
    uint256 public lastCompanyIndex;

    /// @dev Status of combination of (jurisdiction, entityType, EIN) existing
    mapping(bytes32 => bool) public companyExists;

    // EVENTS

    /**
     * @dev Event emitted on company creation
     * @param index Company list index
     * @param info Company info
     */
    event CompanyCreated(uint256 index, CompanyInfo info);

    /**
     * @dev Event emitted on company deletion
     * @param metadataIndex Company metadata index
     */
    event CompanyDeleted(uint256 metadataIndex);

    /**
     * @dev Event emitted on company deletion
     * @param jurisdiction Jurisdiction
     * @param entityType Entity type
     * @param id Queue index
     * @param fee Fee for createPool
     */
    event CompanyFeeUpdated(
        uint256 jurisdiction,
        uint256 entityType,
        uint256 id,
        uint256 fee
    );

    // PUBLIC FUNCTIONS

    /**
     * @dev Create company record
     * @param info Company Info
     */
    function createCompany(CompanyInfo calldata info)
        public
        onlyRole(COMPANIES_MANAGER_ROLE)
    {
        // Check that company data is valid
        require(
            info.jurisdiction > 0 &&
                bytes(info.ein).length != 0 &&
                bytes(info.dateOfIncorporation).length != 0 &&
                info.entityType > 0,
            ExceptionsLibrary.VALUE_ZERO
        );

        // Check that such company does not exist yet and mark it as existing
        bytes32 companyHash = keccak256(
            abi.encodePacked(info.jurisdiction, info.entityType, info.ein)
        );
        require(!companyExists[companyHash], ExceptionsLibrary.INVALID_EIN);
        companyExists[companyHash] = true;

        // Add record to list
        uint256 index = ++lastCompanyIndex;
        companies[index] = info;

        // Add record to queue
        queue[info.jurisdiction][info.entityType].push(index);

        // Emit event
        emit CompanyCreated(index, info);
    }

    /**
     * @dev Lock company record
     * @return info Company info
     */
    function lockCompany(uint256 jurisdiction, uint256 entityType)
        external
        onlyService
        returns (CompanyInfo memory info)
    {
        // Check that company is available
        uint256 queueLength = queue[jurisdiction][entityType].length;
        require(queueLength > 0, ExceptionsLibrary.NO_COMPANY);

        // Get index and pop queue
        uint256 companyIndex = queue[jurisdiction][entityType][queueLength - 1];
        queue[jurisdiction][entityType].pop();

        // Get company info and remove it from list
        info = companies[companyIndex];
        delete companies[companyIndex];
    }

    /**
     * @dev Delete queue record
     * @param jurisdiction Jurisdiction
     * @param entityType Entity type
     * @param id Queue index
     */
    function deleteCompany(
        uint256 jurisdiction,
        uint256 entityType,
        uint256 id
    ) external onlyRole(COMPANIES_MANAGER_ROLE) {
        // Get index and pop queue
        uint256 companyIndex = queue[jurisdiction][entityType][id];
        uint256 lastId = queue[jurisdiction][entityType].length - 1;
        queue[jurisdiction][entityType][id] = queue[jurisdiction][entityType][
            lastId
        ];
        queue[jurisdiction][entityType].pop();

        // Remove company from list
        string memory ein = companies[companyIndex].ein;
        delete companies[companyIndex];

        // Mark company as not existing
        bytes32 companyHash = keccak256(
            abi.encodePacked(jurisdiction, entityType, ein)
        );
        companyExists[companyHash] = false;

        // Emit event
        emit CompanyDeleted(id);
    }

    /**
     * @dev Update company fee
     * @param jurisdiction Jurisdiction
     * @param entityType Entity type
     * @param id Queue index
     * @param fee Fee to update
     */
    function updateCompanyFee(
        uint256 jurisdiction,
        uint256 entityType,
        uint256 id,
        uint256 fee
    ) external onlyRole(COMPANIES_MANAGER_ROLE) {
        // Get company index
        uint256 queueLength = queue[jurisdiction][entityType].length;
        uint256 companyIndex = queue[jurisdiction][entityType][queueLength - 1];

        // Update fee
        companies[companyIndex].fee = fee;

        // Emit event
        emit CompanyFeeUpdated(jurisdiction, entityType, id, fee);
    }

    // PUBLIC VIEW FUNCTIONS

    /**
     * @dev Check if pool available
     * @param jurisdiction Jurisdiction
     * @param entityType Entity type
     * @return Flag if company is available
     */
    function companyAvailable(uint256 jurisdiction, uint256 entityType)
        external
        view
        returns (bool)
    {
        return queue[jurisdiction][entityType].length > 0;
    }
}
