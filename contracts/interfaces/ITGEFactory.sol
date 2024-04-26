// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./ITGE.sol";
import "./ITSE.sol";
import "./IToken.sol";
import "./governor/IGovernanceSettings.sol";

interface ITGEFactory {
    function createSecondaryTGE(
        address token,
        ITGE.TGEInfo calldata tgeInfo,
        IToken.TokenInfo calldata tokenInfo,
        string memory metadataURI,
        address fundReceiverAddress
    ) external;

    function createSecondaryTGEERC1155(
        address token,
        uint256 tokenId,
        string memory uri,
        ITGE.TGEInfo calldata tgeInfo,
        IToken.TokenInfo calldata tokenInfo,
        string memory metadataURI,
        address fundReceiverAddress
    ) external;

    function createPrimaryTGE(
        address poolAddress,
        IToken.TokenInfo memory tokenInfo,
        ITGE.TGEInfo memory tgeInfo,
        string memory metadataURI,
        address fundReceiverAddress,
        IGovernanceSettings.NewGovernanceSettings memory governanceSettings_,
        Roles memory roles
    ) external;

    function createTSE(
        address token,
        uint256 tokenId,
        ITSE.TSEInfo calldata tseInfo,
        string memory metadataURI,
        address recipient
    ) external;

    struct Roles {
        address[] manager;
        address[] secretary;
        address[] executor;
        address[] dividendManager;
    }
}