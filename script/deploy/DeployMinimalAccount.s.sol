//SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";

import {MinimalAccount} from "src/ethereum/MinimalAccount.sol";
import {HelperConfig} from "script/utils/HelperConfig.s.sol";

contract DeployMinimalAccount is Script {
    MinimalAccount minimalAccount;
    HelperConfig helperConfig;

    function run() public {
        (helperConfig, minimalAccount) = deployMinimalAccount();
    }

    function deployMinimalAccount() public returns (HelperConfig, MinimalAccount) {
        HelperConfig _helperConfig = new HelperConfig();
        HelperConfig.NetworkCongig memory config = _helperConfig.getConfig();
        vm.startBroadcast(config.account);
        MinimalAccount _minimalAccount = new MinimalAccount(config.entryPoint);
        _minimalAccount.transferOwnership(msg.sender);
        vm.stopBroadcast();
        return (_helperConfig, _minimalAccount);
    }
}
