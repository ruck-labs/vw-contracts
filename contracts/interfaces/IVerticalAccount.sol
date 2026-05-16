// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.28;

import {IEntryPoint} from "@account-abstraction/contracts/interfaces/IEntryPoint.sol";

interface IVerticalAccount {
    // ─── Types ────────────────────────────────────────────────────────────────

    struct PassKeyInfo {
        bytes32 pubKeyX;
        bytes32 pubKeyY;
        bool    active;
    }

    // ─── Events ───────────────────────────────────────────────────────────────

    event PassKeyGranted(bytes32 indexed credentialIdHash);
    event PassKeyRevoked(bytes32 indexed credentialIdHash);

    // ─── State getters ────────────────────────────────────────────────────────

    function passKeys(bytes32 credentialIdHash) external view returns (PassKeyInfo memory);

    // ─── ERC-4337 ─────────────────────────────────────────────────────────────

    function entryPoint() external view returns (IEntryPoint);
    function getNonce() external view returns (uint256);

    // ─── Initializer ──────────────────────────────────────────────────────────

    function initialize(bytes32 credentialIdHash, bytes32 pubKeyX, bytes32 pubKeyY) external;

    // ─── PassKey management (callable only via execute()) ─────────────────────

    function grantPassKey(bytes32 credentialIdHash, bytes32 pubKeyX, bytes32 pubKeyY) external;
    function revokePassKey(bytes32 credentialIdHash) external;
}
