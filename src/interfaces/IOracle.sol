// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IOracle {
    struct ReserveStats {
        uint256[] reserves;
        string[] symbols;
    }

    function calculatePoolValues(address) external view returns (ReserveStats memory);
}