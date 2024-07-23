//SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {
    IAccount,
    ACCOUNT_VALIDATION_SUCCESS_MAGIC
} from "foundry-era-contracts/src/system-contracts/contracts/interfaces/IAccount.sol";
import {
    Transaction,
    MemoryTransactionHelper
} from "foundry-era-contracts/src/system-contracts/contracts/libraries/MemoryTransactionHelper.sol";
import {SystemContractsCaller} from
    "foundry-era-contracts/src/system-contracts/contracts/libraries/SystemContractsCaller.sol";
import {
    NONCE_HOLDER_SYSTEM_CONTRACT,
    BOOTLOADER_FORMAL_ADDRESS
} from "foundry-era-contracts/src/system-contracts/contracts/Constants.sol";
import {INonceHolder} from "foundry-era-contracts/src/system-contracts/contracts/interfaces/INonceHolder.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract ZKMinimalAccount is IAccount, Ownable {
    using MemoryTransactionHelper for Transaction;
    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    error ZKMinimalAccount__InsufficientFunds();
    error ZKMinimalAccount__NOTFROMBOOTLOADER();

    /*//////////////////////////////////////////////////////////////
                               MODIFIERS
    //////////////////////////////////////////////////////////////*/
    modifier requireBootLoader() {
        if (msg.sender != BOOTLOADER_FORMAL_ADDRESS) {
            revert ZKMinimalAccount__NOTFROMBOOTLOADER();
        }
        _;
    }
    /*//////////////////////////////////////////////////////////////
                           EXTERNAL FUNCTION
    //////////////////////////////////////////////////////////////*/

    constructor() Ownable(msg.sender) {}

    function validateTransaction(
        bytes32, /*_txHash*/
        bytes32, /*_suggestedSignedHash*/
        Transaction calldata _transaction
    ) external payable override requireBootLoader returns (bytes4 magic) {
        SystemContractsCaller.systemCallWithPropagatedRevert(
            uint32(gasleft()),
            address(NONCE_HOLDER_SYSTEM_CONTRACT),
            0,
            abi.encodeCall(INonceHolder.incrementMinNonceIfEquals, (_transaction.nonce))
        );

        uint256 totalRequiredBalance = _transaction.totalRequiredBalance();

        if (totalRequiredBalance > address(this).balance) {
            revert ZKMinimalAccount__InsufficientFunds();
        }

        bytes32 txHash = _transaction.encodeHash();
        address signer = ECDSA.recover(txHash, _transaction.signature);

        if (signer == owner()) {
            magic = ACCOUNT_VALIDATION_SUCCESS_MAGIC;
        } else {
            magic = bytes4(0);
        }
        return magic;
    }

    function executeTransaction(bytes32 _txHash, bytes32 _suggestedSignedHash, Transaction calldata _transaction)
        external
        payable
        override
    {}

    function executeTransactionFromOutside(Transaction calldata _transaction) external payable override {}

    function payForTransaction(bytes32 _txHash, bytes32 _suggestedSignedHash, Transaction calldata _transaction)
        external
        payable
        override
    {}

    function prepareForPaymaster(bytes32 _txHash, bytes32 _possibleSignedHash, Transaction calldata _transaction)
        external
        payable
        override
    {}
    /*//////////////////////////////////////////////////////////////
                           INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/
}
