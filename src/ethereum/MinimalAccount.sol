// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IAccount} from "account-abstraction/contracts/interfaces/IAccount.sol";
import {PackedUserOperation} from "account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {SIG_VALIDATION_FAILED, SIG_VALIDATION_SUCCESS} from "account-abstraction/contracts/core/Helpers.sol";
import {IEntryPoint} from "account-abstraction/contracts/interfaces/IEntryPoint.sol";

/**
 * @title MinimalAccount
 * @notice This is a minimal implementation of a smart contract account following EIP-4337.
 * @dev Implements basic account abstraction with support for the EntryPoint contract.
 */
contract MinimalAccount is IAccount, Ownable {
    /*//////////////////////////////////////////////////////////////
                           ERRORS
    //////////////////////////////////////////////////////////////*/
    error MinimalAccount__NotFromEntryPoint();
    error MinimalAccount__NotFromEntryPointOrOwner();
    error MinimalAccount__CallFailed(bytes);

    /*//////////////////////////////////////////////////////////////
                           STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    /// @notice The entry point contract address
    IEntryPoint private immutable i_entryPoint;

    /*//////////////////////////////////////////////////////////////
                               MODIFIERS
    //////////////////////////////////////////////////////////////*/
    /**
     * @dev Ensures that only the entry point contract can call the function.
     */
    modifier onlyEntryPoint() {
        if (msg.sender != address(i_entryPoint)) {
            revert MinimalAccount__NotFromEntryPoint();
        }
        _;
    }

    /**
     * @dev Ensures that only the entry point contract or the owner can call the function.
     */
    modifier onlyEntryPointOrOwner() {
        if (msg.sender != address(i_entryPoint) && msg.sender != owner()) {
            revert MinimalAccount__NotFromEntryPointOrOwner();
        }
        _;
    }

    /*//////////////////////////////////////////////////////////////
                            FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Constructor to set the entry point contract address and initialize ownership.
     * @param _entryPoint The address of the entry point contract.
     */
    constructor(address _entryPoint) IAccount() Ownable(msg.sender) {
        i_entryPoint = IEntryPoint(_entryPoint);
    }

    /*//////////////////////////////////////////////////////////////
                           EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Receive function to accept ETH transfers.
     */
    receive() external payable {}

    /**
     * @notice Executes a call to the target address with provided value and data.
     * @param target The address to call.
     * @param value The ETH value to send.
     * @param data The call data to send.
     * @dev Can only be called by the entry point contract or the owner.
     */
    function execute(address target, uint256 value, bytes calldata data) external onlyEntryPointOrOwner {
        (bool success, bytes memory result) = target.call{value: value}(data);
        if (!success) {
            revert MinimalAccount__CallFailed(result);
        }
    }

    /**
     * @notice Validates the user operation signature and pays the required prefund.
     * @param userOp The packed user operation.
     * @param userOpHash The hash of the user operation.
     * @param missingAccountFunds The amount of funds required to prefund the account.
     * @return validationData The validation result (success or failure).
     * @dev Can only be called by the entry point contract.
     */
    function validateUserOp(PackedUserOperation calldata userOp, bytes32 userOpHash, uint256 missingAccountFunds)
        external
        override
        onlyEntryPoint
        returns (uint256 validationData)
    {
        validationData = _validateSignature(userOp, userOpHash);
        _payPrefund(missingAccountFunds);
    }

    /*//////////////////////////////////////////////////////////////
                           INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Validates the signature of the user operation.
     * @param userOp The packed user operation.
     * @param userOpHash The hash of the user operation.
     * @return validationData The validation result (success or failure).
     * @dev Uses EIP-191 version of signed hash.
     */
    function _validateSignature(PackedUserOperation calldata userOp, bytes32 userOpHash)
        internal
        view
        returns (uint256 validationData)
    {
        bytes32 ethSignedMessageHash = MessageHashUtils.toEthSignedMessageHash(userOpHash);
        address signer = ECDSA.recover(ethSignedMessageHash, userOp.signature);

        if (signer != owner()) {
            validationData = SIG_VALIDATION_FAILED;
        } else {
            validationData = SIG_VALIDATION_SUCCESS;
        }
    }

    /**
     * @notice Pays the prefund amount to the entry point contract.
     * @param missingAccountFunds The amount of funds required to prefund the account.
     */
    function _payPrefund(uint256 missingAccountFunds) internal {
        if (missingAccountFunds > 0) {
            (bool success,) = payable(msg.sender).call{value: missingAccountFunds, gas: type(uint256).max}("");
            (success); // suppress compiler warning
        }
    }

    /*//////////////////////////////////////////////////////////////
                                GETTERS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Returns the address of the entry point contract.
     * @return The address of the entry point contract.
     */
    function getEntryPoint() external view returns (address) {
        return address(i_entryPoint);
    }
}
