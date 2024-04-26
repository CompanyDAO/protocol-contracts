// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

abstract contract Logger  {

    event CompanyDAOLog(address sender, address receiver, uint256 value, bytes data, address service);

}