// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.28;

import {IVerticalAccount} from "./IVerticalAccount.sol";

interface IVerticalAccountFactory {
    // ─── Events ───────────────────────────────────────────────────────────────

    event AccountCreated(address indexed account, bytes32 indexed credentialIdHash);

    // ─── State getters ────────────────────────────────────────────────────────

    /// @notice The shared VerticalAccount logic contract all proxies delegate to.
    function implementation() external view returns (IVerticalAccount);

    // ─── Functions ────────────────────────────────────────────────────────────

    /**
     * @notice Deploys a new VerticalAccount proxy at a deterministic address.
     *         Returns the existing proxy without reverting if already deployed.
     * @param credentialIdHash  keccak256 of the WebAuthn credential ID.
     * @param pubKeyX           P-256 public key X coordinate.
     * @param pubKeyY           P-256 public key Y coordinate.
     * @param salt              Caller-chosen nonce for address uniqueness.
     */
    function createAccount(
        bytes32 credentialIdHash,
        bytes32 pubKeyX,
        bytes32 pubKeyY,
        uint256 salt
    ) external returns (IVerticalAccount account);

    /**
     * @notice Computes the counterfactual address of a wallet before deployment.
     *         Useful for ERC-4337 initCode construction.
     */
    function getAddress(
        bytes32 credentialIdHash,
        bytes32 pubKeyX,
        bytes32 pubKeyY,
        uint256 salt
    ) external view returns (address);
}
