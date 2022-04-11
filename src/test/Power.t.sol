// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import {DSTest} from "ds-test/test.sol";
import {Storage} from "../lib/Storage.sol";
import {Power} from "../Power.sol";
import {IHevm} from "./utils/IHevm.sol";

/// @title Beluga Power Testing Suite
/// @author Chainvisions
/// @notice Tests for Beluga Power.

contract PowerTest is DSTest {

    /// @notice HEVM, used to manipulate the network via cheatcodes.
    IHevm public constant HEVM = IHevm(HEVM_ADDRESS);

    /// @notice Storage contract, used for access control.
    Storage public store;

    /// @notice Power contract to test.
    Power public power;

    /// @notice Sets up the testing suite.
    function setUp() public {
        store = new Storage();
        store.setGovernance(address(1)); // address(1) will be our exempt;
        power = new Power(address(store));
    }

    /// @notice Tests a BP transfer where the sender's balance must be reset.
    function testTransferSenderReset() public {
        // Setup sender's balance.
        HEVM.startPrank(address(1));
        power.mint(10 * (10 ** 18));
        power.transfer(address(2), 10 * (10 ** 18));

        // Advance the epoch and attempt a transfer from address(2) to address(3).
        power.advanceEpoch();
        HEVM.stopPrank();
        
        uint256 recordedEpoch = power.balanceEpochMark(address(2));
        HEVM.prank(address(2));
        power.transfer(address(3), 10 * (10 ** 18));

        // Check the difference.
        assertGt(power.balanceEpochMark(address(2)), recordedEpoch);
        assertEq(power.balanceOf(address(2)), 0);
    }

    /// @notice Tests a BP transfer where the recipient's balance must be reset.
    function testTransferRecipientReset() public {
        // Setup sender's balance.
        HEVM.startPrank(address(1));
        power.mint(11 * (10 ** 18));
        power.transfer(address(2), 10 * (10 ** 18));

        // Advance the epoch and attempt a transfer from address(1) to address(2).
        power.advanceEpoch();
        uint256 recordedEpoch = power.balanceEpochMark(address(2));
        power.transfer(address(2), 1e18);
        HEVM.stopPrank();

        // Check the adjustment.
        assertGt(power.balanceEpochMark(address(2)), recordedEpoch);
        assertEq(power.balanceOf(address(2)), 1e18);
    }

    /// @notice Tests the `balanceOfEpochAdjusted` resetting on a new epoch.
    function testEpochAdjustmentBalanceReset() public {
        // Setup balances.
        HEVM.startPrank(address(1));
        power.mint(10 * (10 ** 18));
        power.transfer(address(2), 10 * (10 ** 18));

        // Advance epoch and check the adjusted balance.
        power.advanceEpoch();
        HEVM.stopPrank();

        // Check the epoch adjusted balance.
        assertEq(power.balanceOfEpochAdjusted(address(2)), 0);
    }

    /// @notice Tests the `balanceOfEpochAdjusted` remaining static for exempt addresses.
    function testExemptBalanceAdjustment() public {
        // Setup balances.
        HEVM.startPrank(address(1));
        power.mint(10 * (10 ** 18));
        power.transfer(address(2), 10 * (10 ** 18));
        power.exemptAddress(address(2));

        // Advance the epoch and check the adjusted balance.
        power.advanceEpoch();
        HEVM.stopPrank();

        assertEq(power.balanceOfEpochAdjusted(address(2)), 10 * (10 ** 18)); // The balance should remain the same.
    }

    /// @notice Tests the `balanceOfEpochAdjusted` one epoch exempt and
    /// an epoch after being removed of exemption from the BP contract.
    function testExemptionRemoval() public {
        // Setup balances.
        HEVM.startPrank(address(1));
        power.mint(10 * (10 ** 18));
        power.transfer(address(2), 10 * (10 ** 18));
        power.exemptAddress(address(2));

        // Trigger first advancement, here the balance adjusted should be 10 * (10 ** 18)).
        power.advanceEpoch();
        assertEq(power.balanceOfEpochAdjusted(address(2)), 10 * (10 ** 18)); // The balance should remain the same.

        // Now we will remove the exemption of address(2) which should reset the balance after the epoch.
        power.removeExemption(address(2));
        assertEq(power.balanceOfEpochAdjusted(address(2)), 10 * (10 ** 18)); // Vibe check.
        power.advanceEpoch();
        HEVM.stopPrank();

        // Now we can check the balance adjusted, it should have reset to zero.
        assertEq(power.balanceOfEpochAdjusted(address(2)), 0);
    }
}