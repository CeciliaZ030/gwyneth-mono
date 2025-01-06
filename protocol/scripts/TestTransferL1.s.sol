// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "forge-std/console2.sol";

                // {
                //         "address": "0xD9211042f35968820A3407ac3d80C725f8F75c14",
                //         "private_key": "a492823c3e193d6c595f37a18e3c06650cf4c74558cc818b16130b293716106f"
                // },
                // {
                //         "address": "0xD8F3183DEF51A987222D845be228e0Bbb932C222",
                //         "private_key": "c5114526e042343c6d1899cad05e1c00ba588314de9b96929914ee0df18d46b2"
                // },

contract TestTransferL1 is Script {
    address public ACCOUNT_0 = vm.envAddress("ACCOUNT_12");
    address public constant ACCOUNT_1 = 0xD8F3183DEF51A987222D845be228e0Bbb932C222;

    function run() external {
        // Load private key from .env
        uint256 privateKey = vm.envUint("PRIVATE_KEY_12");
        require(privateKey != 0, "invalid private key");

        // Check initial balances
        uint256 initialBalance0 = ACCOUNT_0.balance;
        uint256 initialBalance1 = ACCOUNT_1.balance;

        console2.log("Initial balances:");
        console2.log("Account 0:", initialBalance0);
        console2.log("Account 1:", initialBalance1);

        // Start broadcasting transactions
        vm.startBroadcast(privateKey);

        // Transfer 1 ETH
        payable(ACCOUNT_1).transfer(1 ether);

        vm.stopBroadcast();

        // Check final balances
        uint256 finalBalance0 = ACCOUNT_0.balance;
        uint256 finalBalance1 = ACCOUNT_1.balance;

        console2.log("\nFinal balances:");
        console2.log("Account 0:", finalBalance0);
        console2.log("Account 1:", finalBalance1);

        console2.log("\nBalance changes:");
        console2.log("Account 0:", int256(finalBalance0) - int256(initialBalance0));
        console2.log("Account 1:", int256(finalBalance1) - int256(initialBalance1));
    }
}