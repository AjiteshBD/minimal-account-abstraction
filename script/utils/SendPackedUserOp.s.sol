//SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {PackedUserOperation} from "account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {IEntryPoint} from "account-abstraction/contracts/interfaces/IEntryPoint.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {MasterConstant} from "./MasterConstant.s.sol";

contract SendPackedUserOp is Script, MasterConstant {
    using MessageHashUtils for bytes32;

    function run() external {}

    function generateSignedUserOp(
        bytes memory callData,
        HelperConfig.NetworkCongig memory networkConfig,
        address minimalAccount
    ) public view returns (PackedUserOperation memory) {
        // 1. generate unsigned userop
        uint256 nonce = vm.getNonce(minimalAccount) - 1;
        PackedUserOperation memory userOp = _generateUnsignedUserOp(callData, minimalAccount, nonce);
        //2. get userop hash to sign
        bytes32 userOpHash = IEntryPoint(networkConfig.entryPoint).getUserOpHash(userOp);
        bytes32 digest = userOpHash.toEthSignedMessageHash();
        //3. sign userop and return
        uint8 v;
        bytes32 r;
        bytes32 s;
        if (block.chainid == LOCAL_CHAIN_ID) {
            (v, r, s) = vm.sign(ANVIL_DEFAULT_ACCOUNT_KEY, digest);
        } else {
            (v, r, s) = vm.sign(networkConfig.account, digest);
        }

        userOp.signature = abi.encodePacked(r, s, v); // Order is immport
        return userOp;
    }

    function _generateUnsignedUserOp(bytes memory callData, address sender, uint256 nonce)
        public
        pure
        returns (PackedUserOperation memory)
    {
        uint128 verficationGasLimit = 16777216;
        uint128 callGasLimit = verficationGasLimit;
        uint128 maxPriorityFeePerGas = 256;
        uint128 maxFeePerGas = maxPriorityFeePerGas;

        return PackedUserOperation({
            sender: sender,
            nonce: nonce,
            initCode: hex"",
            callData: callData,
            accountGasLimits: bytes32(uint256(verficationGasLimit) << 128 | callGasLimit), //bitshifting to concatenate
            preVerificationGas: verficationGasLimit,
            gasFees: bytes32(uint256(maxPriorityFeePerGas) << 128 | maxFeePerGas), //bitshifting to concatenate
            paymasterAndData: hex"",
            signature: hex""
        });
    }
}
