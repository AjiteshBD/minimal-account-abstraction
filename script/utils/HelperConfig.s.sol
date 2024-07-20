//SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {MinimalAccount} from "src/ethereum/MinimalAccount.sol";
import {MasterConstant} from "./MasterConstant.s.sol";

contract HelperConfig is Script, MasterConstant {
    error HelperConfig__InvalidChainId();

    struct NetworkCongig {
        address entryPoint;
        address account;
    }

    NetworkCongig private s_localconfig;
    mapping(uint256 chainId => NetworkCongig config) s_chainConfigs;

    constructor() {
        s_chainConfigs[ETH_SEPOLIA_CHAIN_ID] = getSepoliaConfig();
        s_chainConfigs[ZKSYNC_SEPOLIA_CHAIN_ID] = getZkSyncConfig();

        s_localconfig = createOrGetAnvilConfig();
    }

    function run() public view returns (NetworkCongig memory) {
        return getConfig();
    }

    function getConfig() public view returns (NetworkCongig memory) {
        return _getNetowrkConfig(block.chainid);
    }

    function _getNetowrkConfig(uint256 chainId) internal view returns (NetworkCongig memory) {
        if (chainId == LOCAL_CHAIN_ID) {
            return s_localconfig;
        } else if (s_chainConfigs[chainId].account != address(0)) {
            return s_chainConfigs[chainId];
        } else {
            revert HelperConfig__InvalidChainId();
        }
    }

    function getSepoliaConfig() public pure returns (NetworkCongig memory) {
        return NetworkCongig({entryPoint: ETH_SEPOLIA_ENTRYPOINT, account: BURNER_WALLET});
    }

    function getZkSyncConfig() public pure returns (NetworkCongig memory) {
        return NetworkCongig({entryPoint: ZKSYNC_MAINNET_ENTRYPOINT, account: BURNER_WALLET});
    }

    function createOrGetAnvilConfig() public view returns (NetworkCongig memory) {
        if (s_localconfig.account != address(0)) {
            return s_localconfig;
        }

        return NetworkCongig({entryPoint: address(0), account: FOUNDRY_DEFAULT_WALLET});
    }
}
