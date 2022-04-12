// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IVault} from "./interfaces/IVault.sol";
import {IOracle} from "./interfaces/IOracle.sol";
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

    /// @notice Beluga Coral Symphony LP.
    IERC20 public constant CORAL_SYMPHONY = IERC20(0xC7f084bCB91F779617B41602f85102849098D6a2);

    /// @notice Beluga Coral Symphony vault contract.
    IVault public constant CORAL_SYMPHONY_VAULT = IVault(0xeB7D50627bB97e23743E317c51B2CB5F0E0E3909);

    /// @notice Beluga's price oracle contract for fetching pool reserves.
    IOracle public constant BELUGA_ORACLE = IOracle(0xa29129305BEBEf9874c74914D19F51aB16280F30);

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

        IOracle.ReserveStats memory stats = BELUGA_ORACLE.calculatePoolValues(address(CORAL_SYMPHONY));
        nTotal += (stats.reserves[1] * CORAL_SYMPHONY.balanceOf(_account)) / 1e18;
        nTotal += (stats.reserves[1] * CORAL_SYMPHONY_VAULT.underlyingBalanceWithInvestmentForHolder(_account)) / 1e18;

        return nTotal;
    }
}