// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IIDRegistry {
    function isWhitelisted(
        address account,
        address token
    ) external view returns (bool);

    function addToWhitelist(
        address[] calldata accounts,
        bytes32 compliance
    ) external;

    function removeFromWhitelist(
        address[] calldata accounts,
        bytes32 compliance
    ) external;

    function setTokenLists(
        address token,
        address[] calldata newWhitelist,
        address[] calldata newBlacklist
    ) external;

    function addToTokenWhitelist(
        address token,
        address[] calldata accounts
    ) external;

    function removeFromTokenWhitelist(
        address token,
        address[] calldata accounts
    ) external;

    function addToTokenBlacklist(
        address token,
        address[] calldata accounts
    ) external;

    function removeFromTokenBlacklist(
        address token,
        address[] calldata accounts
    ) external;
}
