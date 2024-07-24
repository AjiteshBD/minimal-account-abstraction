//SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {DeployMinimalAccount} from "script/deploy/DeployMinimalAccount.s.sol";
import {MinimalAccount} from "src/ethereum/MinimalAccount.sol";
import {HelperConfig} from "script/utils/HelperConfig.s.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {SendPackedUserOp, PackedUserOperation} from "script/utils/SendPackedUserOp.s.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {IEntryPoint} from "account-abstraction/contracts/interfaces/IEntryPoint.sol";

contract TestMinimalAccount is Test {
    using MessageHashUtils for bytes32;

    HelperConfig helperConfig;
    MinimalAccount minimalAccount;
    ERC20Mock usdc;
    SendPackedUserOp userOp;
    HelperConfig.NetworkCongig config;
    uint256 constant MINT_USDC = 1e18;
    uint256 constant FUND = 1e18;
    uint256 constant MINIMALRETURN_FEE = 1e18;
    address random_user = makeAddr("rand");

    function setUp() public {
        DeployMinimalAccount deployMinimalAccount = new DeployMinimalAccount();
        (helperConfig, minimalAccount) = deployMinimalAccount.deployMinimalAccount();
        usdc = new ERC20Mock();
        userOp = new SendPackedUserOp();
        config = helperConfig.getConfig();
    }

    function testOwnerCanExecute() public {
        uint256 balance = usdc.balanceOf(address(minimalAccount));
        assertEq(balance, 0);
        address dest = address(usdc);
        uint256 value = 0;
        bytes memory data = abi.encodeWithSelector(usdc.mint.selector, address(minimalAccount), MINT_USDC);
        vm.prank(minimalAccount.owner());
        minimalAccount.execute(dest, value, data);
        uint256 newBalance = usdc.balanceOf(address(minimalAccount));
        assertEq(newBalance, MINT_USDC);
    }

    function testNonOwnerCannotExecute() public {
        uint256 balance = usdc.balanceOf(address(minimalAccount));
        assertEq(balance, 0);
        address dest = address(usdc);
        uint256 value = 0;
        bytes memory data = abi.encodeWithSelector(usdc.mint.selector, address(minimalAccount), MINT_USDC);
        vm.prank(random_user);
        vm.expectRevert(MinimalAccount.MinimalAccount__NotFromEntryPointOrOwner.selector);
        minimalAccount.execute(dest, value, data);
    }

    function testRecoverSignerWithUserOp() public view {
        //Arrange
        uint256 balance = usdc.balanceOf(address(minimalAccount));
        assertEq(balance, 0);
        address dest = address(usdc);
        uint256 value = 0;
        bytes memory data = abi.encodeWithSelector(usdc.mint.selector, address(minimalAccount), MINT_USDC);
        bytes memory executeCallData = abi.encodeWithSelector(minimalAccount.execute.selector, dest, value, data);
        PackedUserOperation memory packedUserOp =
            userOp.generateSignedUserOp(executeCallData, config, address(minimalAccount));
        bytes32 packedUserOpHash = IEntryPoint(config.entryPoint).getUserOpHash(packedUserOp);
        //Act
        address signer = ECDSA.recover(packedUserOpHash.toEthSignedMessageHash(), packedUserOp.signature);
        //Assert
        assertEq(signer, minimalAccount.owner());
    }

    function testValidateUserOp() public {
        //Arrange
        uint256 balance = usdc.balanceOf(address(minimalAccount));
        assertEq(balance, 0);
        address dest = address(usdc);
        uint256 value = 0;
        bytes memory data = abi.encodeWithSelector(usdc.mint.selector, address(minimalAccount), MINT_USDC);
        bytes memory executeCallData = abi.encodeWithSelector(minimalAccount.execute.selector, dest, value, data);
        PackedUserOperation memory packedUserOp =
            userOp.generateSignedUserOp(executeCallData, config, address(minimalAccount));
        bytes32 packedUserOpHash = IEntryPoint(config.entryPoint).getUserOpHash(packedUserOp);
        uint256 missingFund = MINIMALRETURN_FEE;
        //Act
        vm.prank(config.entryPoint);
        uint256 validateData = minimalAccount.validateUserOp(packedUserOp, packedUserOpHash, missingFund);
        //Assert
        assertEq(validateData, 0);
    }

    function testEntryPointCanExecuteCommands() public {
        uint256 balance = usdc.balanceOf(address(minimalAccount));
        assertEq(balance, 0);
        address dest = address(usdc);
        uint256 value = 0;
        bytes memory data = abi.encodeWithSelector(usdc.mint.selector, address(minimalAccount), MINT_USDC);
        bytes memory executeCallData = abi.encodeWithSelector(minimalAccount.execute.selector, dest, value, data);
        PackedUserOperation memory packedUserOp =
            userOp.generateSignedUserOp(executeCallData, config, address(minimalAccount));

        vm.deal(address(minimalAccount), FUND);
        PackedUserOperation[] memory ops = new PackedUserOperation[](1);
        ops[0] = packedUserOp;
        vm.prank(random_user);
        IEntryPoint(config.entryPoint).handleOps(ops, payable(random_user));
        uint256 newBalance = usdc.balanceOf(address(minimalAccount));
        assertEq(newBalance, MINT_USDC);
    }
}
