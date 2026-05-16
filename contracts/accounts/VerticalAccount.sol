// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.28;

import {BaseAccount} from "@account-abstraction/contracts/core/BaseAccount.sol";
import {PackedUserOperation} from "@account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import {IEntryPoint} from "@account-abstraction/contracts/interfaces/IEntryPoint.sol";
import {SIG_VALIDATION_FAILED, SIG_VALIDATION_SUCCESS} from "@account-abstraction/contracts/core/Helpers.sol";
import {UUPSUpgradeable} from "@kaiachain/contracts/proxy/utils/UUPSUpgradeable.sol";
import {Initializable} from "@kaiachain/contracts/proxy/utils/Initializable.sol";
import {PassKeyValidator} from "../validators/PassKeyValidator.sol";
import {IVerticalAccount} from "../interfaces/IVerticalAccount.sol";

/**
 * @title VerticalAccount
 * @dev ERC-4337 smart wallet with PassKey (WebAuthn/P-256) authentication.
 *
 * Signature encoding in userOp.signature:
 *   PassKey: abi.encodePacked(uint8(0x01), bytes32(credentialIdHash), abi.encode(WebAuthnAuth))
 */
contract VerticalAccount is BaseAccount, UUPSUpgradeable, Initializable, IVerticalAccount {
    // ─── Constants ────────────────────────────────────────────────────────────

    uint8 private constant SIG_PASSKEY = 0x01;

    // ─── State ────────────────────────────────────────────────────────────────

    IEntryPoint private immutable _entryPoint;
    mapping(bytes32 => PassKeyInfo) private _passKeys;

    // ─── Constructor / Initializer ────────────────────────────────────────────

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(IEntryPoint anEntryPoint) {
        _entryPoint = anEntryPoint;
        _disableInitializers();
    }

    function initialize(
        bytes32 credentialIdHash,
        bytes32 pubKeyX,
        bytes32 pubKeyY
    ) public initializer {
        require(PassKeyValidator.isValidPublicKey(pubKeyX, pubKeyY), "invalid public key");
        _passKeys[credentialIdHash] = PassKeyInfo({pubKeyX: pubKeyX, pubKeyY: pubKeyY, active: true});
        emit PassKeyGranted(credentialIdHash);
    }

    // ─── Modifiers ────────────────────────────────────────────────────────────

    modifier onlySelf() {
        require(msg.sender == address(this), "only via execute");
        _;
    }

    // ─── State getters ────────────────────────────────────────────────────────

    function passKeys(bytes32 credentialIdHash) external view returns (PassKeyInfo memory) {
        return _passKeys[credentialIdHash];
    }

    // ─── ERC-4337 ─────────────────────────────────────────────────────────────

    function entryPoint() public view override(BaseAccount, IVerticalAccount) returns (IEntryPoint) {
        return _entryPoint;
    }

    function getNonce() public view override(BaseAccount, IVerticalAccount) returns (uint256) {
        return super.getNonce();
    }

    function _validateSignature(
        PackedUserOperation calldata userOp,
        bytes32 userOpHash
    ) internal view override returns (uint256) {
        bytes calldata sig = userOp.signature;
        if (sig.length < 33) return SIG_VALIDATION_FAILED;

        uint8 sigType = uint8(sig[0]);
        if (sigType != SIG_PASSKEY) return SIG_VALIDATION_FAILED;

        bytes32 credentialIdHash;
        assembly { credentialIdHash := calldataload(add(sig.offset, 1)) }

        PassKeyInfo storage info = _passKeys[credentialIdHash];
        if (!info.active) return SIG_VALIDATION_FAILED;

        if (!PassKeyValidator.verify(userOpHash, sig[33:], info.pubKeyX, info.pubKeyY)) {
            return SIG_VALIDATION_FAILED;
        }

        return SIG_VALIDATION_SUCCESS;
    }

    // ─── PassKey management (callable only via execute()) ─────────────────────

    function grantPassKey(
        bytes32 credentialIdHash,
        bytes32 pubKeyX,
        bytes32 pubKeyY
    ) external onlySelf {
        require(PassKeyValidator.isValidPublicKey(pubKeyX, pubKeyY), "invalid public key");
        _passKeys[credentialIdHash] = PassKeyInfo({pubKeyX: pubKeyX, pubKeyY: pubKeyY, active: true});
        emit PassKeyGranted(credentialIdHash);
    }

    function revokePassKey(bytes32 credentialIdHash) external onlySelf {
        _passKeys[credentialIdHash].active = false;
        emit PassKeyRevoked(credentialIdHash);
    }

    // ─── UUPS upgrade ─────────────────────────────────────────────────────────

    function _authorizeUpgrade(address) internal view override {
        require(msg.sender == address(this), "only via execute");
    }

    // ─── ETH receive ──────────────────────────────────────────────────────────

    receive() external payable {}
}
