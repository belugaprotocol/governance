// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IVault} from "./interfaces/IVault.sol";
import {Power} from "./Power.sol";

/// @title Beluga Voter Proxy
/// @author Chainvisions
/// @notice A smart contract for calculating BELUGA voting power.

contract VoterProxy {

    /// @notice BELUGA token contract.
    IERC20 public constant BELUGA = IERC20(0x4A13a2cf881f5378DEF61E430139Ed26d843Df9A);

    /// @notice BELUGA profitshare contract.
    IVault public constant PROFITSHARE = IVault(0xba040bc6c54BaBD99990b13D131cFdb515857b3a);

    /// @notice BP contract.
    Power public constant BP = Power(0x8cE9726e35aAb00B765e2470EBB15c46Bb06d8b9);

    /// @notice Name of the voting proxy.
    string public constant name = "Beluga Voting Power";

    /// @notice Symbol of the voting proxy.
    string public constant symbol = "vBELUGA";

    /// @notice Calculates the voting power of an account.
    /// @param _account Account to calculate the voting power of.
    /// @return The total voting power held by the account.
    function balanceOf(address _account) external view returns (uint256) {
        uint256 nTotal;

        // Calculate total.
        nTotal += BELUGA.balanceOf(_account);
        nTotal += PROFITSHARE.underlyingBalanceWithInvestmentForHolder(_account);
        nTotal += BP.balanceOfEpochAdjusted(_account);

        return nTotal;
    }
}