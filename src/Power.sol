// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Governable} from "./lib/Governable.sol";

/// @title Beluga Power
/// @author Chainvisions
/// @notice A token that represents 1 BELUGA in voting power.

contract Power is ERC20("Beluga Power", "BP"), Governable {

    constructor(address _store) Governable(_store) {
        epochExempt[governance()] = true;
    }

    /// @notice Latest power epoch, the first epoch should be 1.
    uint256 public latestEpoch;

    /// @notice Last epoch that a user's balance was handled.
    mapping(address => uint256) public balanceEpochMark;

    /// @notice Balance of a user at a recorded epoch.
    mapping(address => mapping(uint256 => uint256)) public balanceAtRecordedEpoch;

    /// @notice Addresses that are not affected by epochs.
    mapping(address => bool) public epochExempt;

    /// @notice Emitted when an account's balance is reset to the latest epoch.
    event ResetToNextEpoch(address indexed account, uint256 lastRecorded, uint256 latest);

    /// @notice Mints new BP tokens.
    /// @param _amount Amount of BP to mint.
    function mint(uint256 _amount) external onlyGovernance {
        _mint(msg.sender, _amount);
    }

    /// @notice Fetches the epoch-adjusted balance of an account.
    /// @param _account Account to fetch the epoch adjusted balance of.
    /// @return The epoch adjusted balance of `_account`.
    function balanceOfEpochAdjusted(address _account) external view returns (uint256) {
        // First we check if they're exempt or not.
        if(epochExempt[_account]) {
            // If they are, a simple `balanceOf` will suffice.
            return balanceOf(_account);
        } else {
            // Else, we need to check the last epoch marked on their account.
            if(balanceEpochMark[_account] != latestEpoch) {
                // In the case of their marked epoch being outdated,
                // we can simply return a pure value.
                return 0;
            } else {
                // If they are in date with the latest epoch, balanceOf also suffices.
                return balanceOf(_account);
            }
        }
    }

    function _transfer(address _sender, address _recipient, uint256 _amount) internal override {
        // Check if the sender is exempt or not. If they aren't, we will reset
        // their balance and end the transfer there. If not, we can let them through.
        if(!epochExempt[_sender]) {
            // Check last recorded epoch.
            uint256 lastEpoch = balanceEpochMark[_sender];
            uint256 latest = latestEpoch;
            if(lastEpoch != latest) {
                // Reset balances and mark with new epoch.
                uint256 balance = balanceOf(_sender);
                balanceAtRecordedEpoch[_sender][lastEpoch] = balance;
                _burn(_sender, balance);
                balanceEpochMark[_sender] = latest;
                emit ResetToNextEpoch(_sender, lastEpoch, latest);
                return; // If the sender has to be reset, the transfer is over.
            }
        }

        // Now we can check the recipient.
        if(!epochExempt[_recipient]) {
            // Check last recorded epoch.
            uint256 lastEpoch = balanceEpochMark[_recipient];
            uint256 latest = latestEpoch;
            if(lastEpoch != latest) {
                // Reset balances and mark with new epoch.
                uint256 balance = balanceOf(_recipient);
                balanceAtRecordedEpoch[_recipient][lastEpoch] = balance;
                _burn(_recipient, balance);
                balanceEpochMark[_recipient] = latest;
                emit ResetToNextEpoch(_recipient, lastEpoch, latest);
            }
        }

        // At this point, all checks have been made and we can perform a transfer.
        // We do not need to check the epoch adjusted balances as `_transfer` does that for us.
        super._transfer(_sender, _recipient, _amount);
    }
}