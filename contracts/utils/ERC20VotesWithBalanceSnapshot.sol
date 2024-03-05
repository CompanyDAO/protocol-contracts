// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20VotesUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ArraysUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";

abstract contract ERC20VotesWithBalanceSnapshot is ERC20VotesUpgradeable {
    using ArraysUpgradeable for uint256[];
    using CountersUpgradeable for CountersUpgradeable.Counter;

    // Struct to store snapshot data
    struct Snapshots {
        uint256[] ids;
        uint256[] values;
    }

    // Mapping of user address to snapshots
    mapping(address => Snapshots) private _accountBalanceSnapshots;
    // Mapping of snapshot id to total supply at that snapshot
    mapping(uint256 => Snapshots) private _totalSupplySnapshots;

    // Counter for current snapshot id
    CountersUpgradeable.Counter private _currentSnapshotId;

    // Event to emit when a snapshot is created
    event Snapshot(uint256 id);

    function _snapshot() internal virtual returns (uint256) {
        _currentSnapshotId.increment();
        uint256 currentId = _currentSnapshotId.current();

        // if the last snapshot was in the current block, do not create a new one
        if (_lastSnapshotId(_totalSupplySnapshots[currentId].ids) == block.number) {
            return currentId;
        }

        _updateSnapshot(_totalSupplySnapshots[currentId], totalSupply());

        emit Snapshot(currentId);
        return currentId;
    }

    function balanceOfAt(address account, uint256 snapshotId) public view returns (uint256) {
        require(snapshotId > 0 && snapshotId <= _currentSnapshotId.current(), "ERC20Snapshot: invalid snapshot id");

        (bool snapshotted, uint256 value) = _valueAt(
            snapshotId,
            _accountBalanceSnapshots[account]
        );
        return snapshotted ? value : balanceOf(account);
    }

     function totalSupplyAtSnapshotId(uint256 snapshotId) public view virtual returns (uint256) {
        require(snapshotId > 0 && snapshotId <= _currentSnapshotId.current(), "ERC20Snapshot: invalid snapshot id");

        (bool snapshotted, uint256 value) = _valueAt(
            snapshotId,
            _totalSupplySnapshots[snapshotId]
        );
        return snapshotted ? value : totalSupply();
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal virtual override(ERC20Upgradeable) // Specify the correct parent contract here
    {
        super._beforeTokenTransfer(from, to, amount); // Call the parent implementation

        if (from == address(0)) {
            // Minting tokens
            _updateAccountSnapshot(to);
        } else if (to == address(0)) {
            // Burning tokens
            _updateAccountSnapshot(from);
        } else {
            // Normal transfer
            _updateAccountSnapshot(from);
            _updateAccountSnapshot(to);
        }
    }

    function _updateAccountSnapshot(address account) private {
        _updateSnapshot(_accountBalanceSnapshots[account], balanceOf(account));
    }

    function _updateSnapshot(Snapshots storage snapshots, uint256 currentValue) private {
        uint256 currentId = _currentSnapshotId.current();
        if (_lastSnapshotId(snapshots.ids) < currentId) {
            snapshots.ids.push(currentId);
            snapshots.values.push(currentValue);
        } 
    }

    function _lastSnapshotId(uint256[] storage ids) private view returns (uint256) {
        if (ids.length == 0) {
            return 0;
        } else {
            return ids[ids.length - 1];
        }
    }

    function _valueAt(
        uint256 snapshotId,
        Snapshots storage snapshots
    ) private view returns (bool, uint256) {
        uint256 index = snapshots.ids.findUpperBound(snapshotId);

        if (index == snapshots.ids.length) {
            return (false, 0);
        } else {
            return (true, snapshots.values[index]);
        }
    }
}
