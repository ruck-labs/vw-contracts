// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.28;

import {Create2} from "@kaiachain/contracts/utils/Create2.sol";
import {ERC1967Proxy} from "@kaiachain/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {IEntryPoint} from "@account-abstraction/contracts/interfaces/IEntryPoint.sol";
import {VerticalAccount} from "./VerticalAccount.sol";
import {IVerticalAccount} from "../interfaces/IVerticalAccount.sol";
import {IVerticalAccountFactory} from "../interfaces/IVerticalAccountFactory.sol";

/**
 * @title VerticalAccountFactory
 * @dev Deploys VerticalAccount UUPS proxies at deterministic addresses via CREATE2.
 *
 * One shared implementation is deployed in the constructor.
 * Each wallet is an ERC1967Proxy pointing to that implementation, initialized
 * with its own passkey and fee recipient.
 *
 * createAccount() is idempotent: calling it again with the same parameters
 * returns the already-deployed proxy without reverting.
 */
contract VerticalAccountFactory is IVerticalAccountFactory {
    VerticalAccount private immutable _impl;

    constructor(IEntryPoint entryPoint) {
        _impl = new VerticalAccount(entryPoint);
    }

    /// @inheritdoc IVerticalAccountFactory
    function implementation() external view returns (IVerticalAccount) {
        return _impl;
    }

    /// @inheritdoc IVerticalAccountFactory
    function createAccount(
        bytes32 credentialIdHash,
        bytes32 pubKeyX,
        bytes32 pubKeyY,
        uint256 salt
    ) external returns (IVerticalAccount account) {
        address predicted = getAddress(credentialIdHash, pubKeyX, pubKeyY, salt);

        if (predicted.code.length > 0) {
            return IVerticalAccount(predicted);
        }

        bytes memory initData = abi.encodeCall(
            IVerticalAccount.initialize,
            (credentialIdHash, pubKeyX, pubKeyY)
        );

        bytes32 create2Salt = _salt(credentialIdHash, pubKeyX, pubKeyY, salt);

        account = IVerticalAccount(
            address(new ERC1967Proxy{salt: create2Salt}(address(_impl), initData))
        );

        emit AccountCreated(address(account), credentialIdHash);
    }

    /// @inheritdoc IVerticalAccountFactory
    function getAddress(
        bytes32 credentialIdHash,
        bytes32 pubKeyX,
        bytes32 pubKeyY,
        uint256 salt
    ) public view returns (address) {
        bytes memory initData = abi.encodeCall(
            IVerticalAccount.initialize,
            (credentialIdHash, pubKeyX, pubKeyY)
        );

        bytes32 bytecodeHash = keccak256(abi.encodePacked(
            type(ERC1967Proxy).creationCode,
            abi.encode(address(_impl), initData)
        ));

        return Create2.computeAddress(
            _salt(credentialIdHash, pubKeyX, pubKeyY, salt),
            bytecodeHash
        );
    }

    function _salt(
        bytes32 credentialIdHash,
        bytes32 pubKeyX,
        bytes32 pubKeyY,
        uint256 salt
    ) private pure returns (bytes32) {
        return keccak256(abi.encode(credentialIdHash, pubKeyX, pubKeyY, salt));
    }
}
