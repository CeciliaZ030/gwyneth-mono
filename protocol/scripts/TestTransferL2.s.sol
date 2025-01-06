// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "forge-std/console2.sol";

contract TestTransferL2 is Script {
    address public constant ACCOUNT_0 = 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC;
    address public constant ACCOUNT_1 = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;

    function run() external {
        // Load private key from .env
        uint256 privateKey = vm.envUint("PRIVATE_KEY_2");
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