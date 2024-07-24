//SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {ZKMinimalAccount} from "../../src/zksync/ZkMinimalAccount.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {
    Transaction,
    MemoryTransactionHelper
} from "foundry-era-contracts/src/system-contracts/contracts/libraries/MemoryTransactionHelper.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {MasterConstant} from "script/utils/MasterConstant.s.sol";
import {
    NONCE_HOLDER_SYSTEM_CONTRACT,
    BOOTLOADER_FORMAL_ADDRESS,
    DEPLOYER_SYSTEM_CONTRACT
} from "foundry-era-contracts/src/system-contracts/contracts/Constants.sol";

import {
    IAccount,
    ACCOUNT_VALIDATION_SUCCESS_MAGIC
} from "foundry-era-contracts/src/system-contracts/contracts/interfaces/IAccount.sol";

contract ZkMinimalAccount is Test, MasterConstant {
    using MessageHashUtils for bytes32;

    ZKMinimalAccount zkMinimalAccount;
    ERC20Mock usdc;
    uint256 constant MINT_USDC = 1e18;
    bytes32 constant EMPTY_BYTES32 = bytes32(0);

    function setUp() public {
        zkMinimalAccount = new ZKMinimalAccount();
        zkMinimalAccount.transferOwnership(ANVIL_DEFAULT_ACCOUNT);
        usdc = new ERC20Mock();
        vm.deal(address(zkMinimalAccount), MINT_USDC);
    }

    function testZKOwnerCanExecuteCommand() public {
        //Arrage
        address dest = address(usdc);
        uint256 value = 0;
        bytes memory data = abi.encodeWithSelector(usdc.mint.selector, address(zkMinimalAccount), MINT_USDC);
        //Act
        Transaction memory txn = _createUnsignedTxnHas(zkMinimalAccount.owner(), 113, dest, value, data);
        //Assert
        vm.prank(zkMinimalAccount.owner());
        zkMinimalAccount.executeTransaction(EMPTY_BYTES32, EMPTY_BYTES32, txn);
        assertEq(usdc.balanceOf(address(zkMinimalAccount)), MINT_USDC);
    }

    function testZKValidateTransaction() public {
        //Arrage
        address dest = address(usdc);
        uint256 value = 0;
        bytes memory data = abi.encodeWithSelector(usdc.mint.selector, address(zkMinimalAccount), MINT_USDC);
        //Act
        Transaction memory txn = _createUnsignedTxnHas(zkMinimalAccount.owner(), 113, dest, value, data);

        txn = _signTransaction(txn);
        //Assert
        vm.prank(BOOTLOADER_FORMAL_ADDRESS);
        bytes4 magic = zkMinimalAccount.validateTransaction(EMPTY_BYTES32, EMPTY_BYTES32, txn);
        assertEq(magic, ACCOUNT_VALIDATION_SUCCESS_MAGIC);
    }

    /*//////////////////////////////////////////////////////////////
                           INTERNAL FUNCTION
    //////////////////////////////////////////////////////////////*/

    function _signTransaction(Transaction memory txn) internal view returns (Transaction memory) {
        bytes32 unsignedtxn = MemoryTransactionHelper.encodeHash(txn);
        // bytes32 digest = unsignedtxn.toEthSignedMessageHash();
        //3. sign
        uint8 v;
        bytes32 r;
        bytes32 s;
        (v, r, s) = vm.sign(ANVIL_DEFAULT_ACCOUNT_KEY, unsignedtxn);
        Transaction memory signedtrx = txn;
        signedtrx.signature = abi.encodePacked(r, s, v); // Order is immport
        return signedtrx;
    }

    function _createUnsignedTxnHas(address from, uint8 transactionType, address to, uint256 value, bytes memory data)
        internal
        view
        returns (Transaction memory txn)
    {
        uint256 nonce = vm.getNonce(address(zkMinimalAccount));
        bytes32[] memory factoryDeps = new bytes32[](0);
        return Transaction({
            txType: transactionType,
            from: uint256(uint160(from)),
            to: uint256(uint160(to)),
            gasLimit: 16777216,
            gasPerPubdataByteLimit: 16777216,
            maxFeePerGas: 16777216,
            maxPriorityFeePerGas: 16777216,
            paymaster: 0,
            nonce: nonce,
            value: value,
            reserved: [uint256(0), uint256(0), uint256(0), uint256(0)],
            data: data,
            signature: hex"",
            factoryDeps: factoryDeps,
            paymasterInput: hex"",
            reservedDynamic: hex""
        });
    }
}
