// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "./interfaces/registry/IRegistry.sol";
import "./interfaces/IIDRegistry.sol";
import "./interfaces/IService.sol";
import "./interfaces/IToken.sol";
import "./utils/Logger.sol";

contract IDRegistry is AccessControlEnumerableUpgradeable, Logger {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    IRegistry public registry;
    bytes32 public constant COMPLIANCE_ADMIN = keccak256("COMPLIANCE_ADMIN");

    // Original compliance whitelists
    mapping(bytes32 => mapping(address => bool)) private _whitelists;

    // New token-specific whitelists and blacklists
    mapping(address => EnumerableSetUpgradeable.AddressSet)
        private _tokenWhitelists;
    mapping(address => EnumerableSetUpgradeable.AddressSet)
        private _tokenBlacklists;

    event ComplianceAdminAdded(
        address indexed admin,
        bytes32 indexed compliance
    );
    event ComplianceAdminRemoved(
        address indexed admin,
        bytes32 indexed compliance
    );
    event Whitelisted(
        address indexed account,
        bytes32 indexed compliance,
        bool status
    );
    event TokenWhitelisted(
        address indexed token,
        address indexed account,
        bool status
    );
    event TokenBlacklisted(
        address indexed token,
        address indexed account,
        bool status
    );

    modifier onlySuperAdmin() {
        require(
            IService(registry.service()).hasRole(
                IService(registry.service()).ADMIN_ROLE(),
                msg.sender
            ),
            "IDRegistry: Caller is not a super admin"
        );
        _;
    }

    modifier onlyComplianceAdmin(bytes32 compliance) {
        require(
            IService(registry.service()).hasRole(
                IService(registry.service()).SERVICE_MANAGER_ROLE(),
                msg.sender
            ) ||
                (hasRole(COMPLIANCE_ADMIN, msg.sender) &&
                    hasRole(compliance, msg.sender)),
            "IDRegistry: Caller is not a compliance admin"
        );
        _;
    }

    constructor() {
        _disableInitializers();
    }

    function initialize(IRegistry registry_) external initializer {
        __AccessControlEnumerable_init();
        registry = registry_;
    }

    function addComplianceAdmin(
        address admin,
        bytes32 compliance
    ) public onlySuperAdmin {
        _grantRole(COMPLIANCE_ADMIN, admin);
        _grantRole(compliance, admin);
        emit ComplianceAdminAdded(admin, compliance);
    }

    function removeComplianceAdmin(
        address admin,
        bytes32 compliance
    ) public onlySuperAdmin {
        _revokeRole(COMPLIANCE_ADMIN, admin);
        _revokeRole(compliance, admin);
        emit ComplianceAdminRemoved(admin, compliance);
    }

    function addToWhitelist(
        address[] calldata accounts,
        bytes32 compliance
    ) external onlyComplianceAdmin(compliance) {
        for (uint256 i = 0; i < accounts.length; i++) {
            _whitelists[compliance][accounts[i]] = true;
        }
        emit CompanyDAOLog(
            _msgSender(),
            address(this),
            0,
            abi.encodeWithSelector(
                IIDRegistry.addToWhitelist.selector,
                accounts,
                compliance
            ),
            address(registry.service())
        );
    }

    function removeFromWhitelist(
        address[] calldata accounts,
        bytes32 compliance
    ) external onlyComplianceAdmin(compliance) {
        for (uint256 i = 0; i < accounts.length; i++) {
            _whitelists[compliance][accounts[i]] = false;
        }
        emit CompanyDAOLog(
            _msgSender(),
            address(this),
            0,
            abi.encodeWithSelector(
                IIDRegistry.removeFromWhitelist.selector,
                accounts,
                compliance
            ),
            address(registry.service())
        );
    }

    /**
     * @dev Checks if an address is associated with service contracts
     * @param account Address to check
     * @return True if the address is a service contract, false otherwise
     */
    function isServiceContract(address account) public view returns (bool) {
        return
            registry.typeOf(account) != IRecordsRegistry.ContractType.None ||
            address(registry.service().vesting()) == account ||
            address(registry.service()) == account ||
            address(registry.service().tgeFactory()) == account ||
            address(registry.service().tokenFactory()) == account ||
            address(0) == account;
    }

    /**
     * @dev Checks if an address is whitelisted for a specific compliance
     * @param account Address to check the whitelist status for
     * @param token token address
     * @return True if the address is whitelisted or if the compliance identifier is zero bytes
     */
    function isWhitelisted(
        address account,
        address token
    ) public view returns (bool) {
        bytes32 compliance = IToken(token).compliance();
        return
            isServiceContract(account) ||
            ((compliance == bytes32(0) || _whitelists[compliance][account]) &&
                isWhitelistedForToken(account, token) &&
                !isBlacklistedForToken(account, token));
    }

    function isWhitelistedForToken(
        address token,
        address account
    ) public view returns (bool) {
        return (_tokenWhitelists[token].values().length == 0 ||
            _tokenWhitelists[token].contains(account));
    }

    function isBlacklistedForToken(
        address token,
        address account
    ) public view returns (bool) {
        return _tokenBlacklists[token].contains(account);
    }

    // Retrieves the whitelist for a specific token
    function getTokenWhitelist(
        address token
    ) public view returns (address[] memory) {
        uint256 whitelistSize = _tokenWhitelists[token].length();
        address[] memory whitelistAddresses = new address[](whitelistSize);

        for (uint256 i = 0; i < whitelistSize; i++) {
            whitelistAddresses[i] = _tokenWhitelists[token].at(i);
        }

        return whitelistAddresses;
    }

    // Retrieves the blacklist for a specific token
    function getTokenBlacklist(
        address token
    ) public view returns (address[] memory) {
        uint256 blacklistSize = _tokenBlacklists[token].length();
        address[] memory blacklistAddresses = new address[](blacklistSize);

        for (uint256 i = 0; i < blacklistSize; i++) {
            blacklistAddresses[i] = _tokenBlacklists[token].at(i);
        }

        return blacklistAddresses;
    }

    // Updates both the whitelist and blacklist for a specific token
    function setTokenLists(
        address token,
        address[] calldata newWhitelist,
        address[] calldata newBlacklist
    ) external {
        require(
            IPool(IToken(token).pool()).isPoolSecretary(msg.sender),
            "IDRegistry: Caller is not a pool secretary"
        );

        // Reset whitelist - remove existing entries
        while (_tokenWhitelists[token].length() > 0) {
            address lastWhitelistAddress = _tokenWhitelists[token].at(
                _tokenWhitelists[token].length() - 1
            );
            _tokenWhitelists[token].remove(lastWhitelistAddress);
        }
        // Populate the new whitelist
        for (uint256 i = 0; i < newWhitelist.length; i++) {
            _tokenWhitelists[token].add(newWhitelist[i]);
        }

        // Reset blacklist - remove existing entries
        while (_tokenBlacklists[token].length() > 0) {
            address lastBlacklistAddress = _tokenBlacklists[token].at(
                _tokenBlacklists[token].length() - 1
            );
            _tokenBlacklists[token].remove(lastBlacklistAddress);
        }
        // Populate the new blacklist
        for (uint256 i = 0; i < newBlacklist.length; i++) {
            _tokenBlacklists[token].add(newBlacklist[i]);
        }

        emit CompanyDAOLog(
            _msgSender(),
            address(this),
            0,
            abi.encodeWithSelector(
                IIDRegistry.setTokenLists.selector,
                token,
                newWhitelist,
                newBlacklist
            ),
            address(registry.service())
        );
    }

    // Adds multiple addresses to the token-specific whitelist
    function addToTokenWhitelist(
        address token,
        address[] calldata accounts
    ) external {
        require(
            IPool(IToken(token).pool()).isPoolSecretary(msg.sender),
            "IDRegistry: Caller is not a pool secretary"
        );

        for (uint256 i = 0; i < accounts.length; i++) {
            _tokenWhitelists[token].add(accounts[i]);
        }

        emit CompanyDAOLog(
            _msgSender(),
            address(this),
            0,
            abi.encodeWithSelector(
                IIDRegistry.addToTokenWhitelist.selector,
                token,
                accounts
            ),
            address(registry.service())
        );
    }

    // Removes multiple addresses from the token-specific whitelist
    function removeFromTokenWhitelist(
        address token,
        address[] calldata accounts
    ) external {
        require(
            IPool(IToken(token).pool()).isPoolSecretary(msg.sender),
            "IDRegistry: Caller is not a pool secretary"
        );

        for (uint256 i = 0; i < accounts.length; i++) {
            _tokenWhitelists[token].remove(accounts[i]);
        }

        emit CompanyDAOLog(
            _msgSender(),
            address(this),
            0,
            abi.encodeWithSelector(
                IIDRegistry.removeFromTokenWhitelist.selector,
                token,
                accounts
            ),
            address(registry.service())
        );
    }

    // Adds multiple addresses to the token-specific blacklist
    function addToTokenBlacklist(
        address token,
        address[] calldata accounts
    ) external {
        require(
            IPool(IToken(token).pool()).isPoolSecretary(msg.sender),
            "IDRegistry: Caller is not a pool secretary"
        );

        for (uint256 i = 0; i < accounts.length; i++) {
            _tokenBlacklists[token].add(accounts[i]);
        }

        emit CompanyDAOLog(
            _msgSender(),
            address(this),
            0,
            abi.encodeWithSelector(
                IIDRegistry.addToTokenBlacklist.selector,
                token,
                accounts
            ),
            address(registry.service())
        );
    }

    // Removes multiple addresses from the token-specific blacklist
    function removeFromTokenBlacklist(
        address token,
        address[] calldata accounts
    ) external {
        require(
            IPool(IToken(token).pool()).isPoolSecretary(msg.sender),
            "IDRegistry: Caller is not a pool secretary"
        );

        for (uint256 i = 0; i < accounts.length; i++) {
            _tokenBlacklists[token].remove(accounts[i]);
        }

        emit CompanyDAOLog(
            _msgSender(),
            address(this),
            0,
            abi.encodeWithSelector(
                IIDRegistry.removeFromTokenBlacklist.selector,
                token,
                accounts
            ),
            address(registry.service())
        );
    }

    /**
     * @dev Returns a list of addresses that are whitelisted for a specific compliance.
     * @param compliance Compliance identifier.
     * @param start The starting index for iterating through the addresses.
     * @param limit The maximum number of addresses to return (to manage gas costs).
     * @return whitelistedAddresses An array of addresses that are whitelisted.
     */
    function getWhitelistedAddresses(
        bytes32 compliance,
        uint256 start,
        uint256 limit
    ) public view returns (address[] memory whitelistedAddresses) {
        uint256 roleMemberCount = getRoleMemberCount(compliance);

        // Ensure the start index is within the role member count
        if (start >= roleMemberCount) {
            return new address[](0);
        }

        // Adjust the limit to ensure it does not exceed the number of role members
        uint256 adjustedLimit = MathUpgradeable.min(
            roleMemberCount - start,
            limit
        );

        // Initialize the array with the adjusted size
        whitelistedAddresses = new address[](adjustedLimit);

        // Populate the array with whitelisted addresses
        for (uint256 i = 0; i < adjustedLimit; i++) {
            whitelistedAddresses[i] = getRoleMember(compliance, start + i);
        }

        return whitelistedAddresses;
    }
}
