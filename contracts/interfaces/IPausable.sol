// SPDX-License-Identifier: MIT

import "./registry/ICompaniesRegistry.sol";

pragma solidity 0.8.17;

interface IPausable {
    function paused() external view returns (bool);

    function isPoolSecretary(address account) external view returns (bool);

    function companyInfo()
        external
        returns (ICompaniesRegistry.CompanyInfo memory);
}
