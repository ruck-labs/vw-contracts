// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.28;

import {WebAuthn} from "@openzeppelin/contracts/utils/cryptography/WebAuthn.sol";
import {P256} from "@openzeppelin/contracts/utils/cryptography/P256.sol";

/**
 * @title PassKeyValidator
 * @dev Stateless library for verifying WebAuthn/PassKey (P-256/secp256r1) signatures.
 *
 * Used by VerticalAccount._validateSignature(). Public key management is the
 * responsibility of the caller.
 *
 * On Kaia, P256.verify() uses the RIP-7212 precompile at 0x100 (~3k gas vs ~300k gas).
 *
 * Signature encoding:
 *   userOp.signature = abi.encode(WebAuthn.WebAuthnAuth)
 */
library PassKeyValidator {
    /**
     * @dev Verifies a WebAuthn authentication assertion.
     *
     * @param userOpHash  ERC-4337 userOpHash, used as the WebAuthn challenge.
     * @param signature   ABI-encoded WebAuthn.WebAuthnAuth struct.
     * @param pubKeyX     P-256 public key X coordinate.
     * @param pubKeyY     P-256 public key Y coordinate.
     * @return true if the signature is valid.
     */
    function verify(
        bytes32 userOpHash,
        bytes calldata signature,
        bytes32 pubKeyX,
        bytes32 pubKeyY
    ) internal view returns (bool) {
        (bool success, WebAuthn.WebAuthnAuth calldata auth) = WebAuthn.tryDecodeAuth(signature);
        if (!success) return false;

        return WebAuthn.verify(
            abi.encodePacked(userOpHash),
            auth,
            pubKeyX,
            pubKeyY,
            false // requireUV: PIN・生体認証どちらも許可
        );
    }

    /**
     * @dev Checks if the given coordinates form a valid P-256 public key.
     * Call this during PassKey registration in VerticalAccount.
     */
    function isValidPublicKey(bytes32 pubKeyX, bytes32 pubKeyY) internal pure returns (bool) {
        return P256.isValidPublicKey(pubKeyX, pubKeyY);
    }
}
