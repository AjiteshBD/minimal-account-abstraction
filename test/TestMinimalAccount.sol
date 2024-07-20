//SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {DeployMinimalAccount} from "script/deploy/DeployMinimalAccount.s.sol";
import {MinimalAccount} from "src/ethereum/MinimalAccount.sol";
import {HelperConfig} from "script/utils/HelperConfig.s.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

contract TestMinimalAccount is Test {
    HelperConfig helperConfig;
    MinimalAccount minimalAccount;
    ERC20Mock usdc;
    uint256 constant MINT_USDC = 1e18;
    address random_user = makeAddr("rand");

    function setUp() public {
        DeployMinimalAccount deployMinimalAccount = new DeployMinimalAccount();
        (helperConfig, minimalAccount) = deployMinimalAccount.deployMinimalAccount();
        usdc = new ERC20Mock();
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
}
