//SPDX-License-Identifier: MIT

import {Test} from "forge-std/Test.sol";
import {ZKMinimalAccount} from "../../src/zksync/ZkMinimalAccount.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {
    Transaction,
    MemoryTransactionHelper
} from "foundry-era-contracts/src/system-contracts/contracts/libraries/MemoryTransactionHelper.sol";

contract ZkMinimalAccount is Test {
    ZKMinimalAccount zkMinimalAccount;
    ERC20Mock usdc;
    uint256 constant MINT_USDC = 1e18;
    bytes32 constant EMPTY_BYTES32 = bytes32(0);

    function setUp() public {
        zkMinimalAccount = new ZKMinimalAccount();
        usdc = new ERC20Mock();
    }

    function testZKOwnerCanExecuteCommand() public {
        //Arrage
        address dest = address(usdc);
        uint256 value = 0;
        bytes memory data = abi.encodeWithSelector(usdc.mint.selector, address(zkMinimalAccount), MINT_USDC);
        //Act
        Transaction memory txn = _createUnsignedTxnHas(address(zkMinimalAccount), 0, dest, value, data);
        //Assert
        vm.prank(zkMinimalAccount.owner());
        zkMinimalAccount.executeTransaction(EMPTY_BYTES32, EMPTY_BYTES32, txn);
        assertEq(usdc.balanceOf(address(zkMinimalAccount)), MINT_USDC);
    }

    /*//////////////////////////////////////////////////////////////
                           INTERNAL FUNCTION
    //////////////////////////////////////////////////////////////*/

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
