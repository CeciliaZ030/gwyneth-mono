
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/utils/Strings.sol";

import "../src/L1/TaikoL1.sol";
import "../src/L1/ChainProver.sol";
import "../src/L1/VerifierRegistry.sol";
import "../src/tko/TaikoToken.sol";
import "../src/L1/provers/GuardianProver.sol";
import "../src/L1/verifiers/MockSgxVerifier.sol"; // Avoid proof verification for now!
import "../test/DeployCapability.sol";
import { P256Verifier } from "p256-verifier/src/P256Verifier.sol";


/// @title DeployOnL1
/// @notice This script deploys the core Taiko protocol smart contract on L1,
/// initializing the rollup.
contract DeployOnL1 is DeployCapability {
 address public MAINNET_CONTRACT_OWNER = vm.envAddress("MAINNET_CONTRACT_OWNER");

    modifier broadcast() {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        require(privateKey != 0, "invalid priv key");
        vm.startBroadcast();
        _;
        vm.stopBroadcast();
    }

    function run() external broadcast {
        require(vm.envBytes32("L2_GENESIS_HASH") != 0, "L2_GENESIS_HASH");
        address contractOwner = MAINNET_CONTRACT_OWNER;

        // ---------------------------------------------------------------
        // Deploy shared contracts
        (address sharedAddressManager) = deploySharedContracts(contractOwner);
        console2.log("sharedAddressManager: ", sharedAddressManager);
        // ---------------------------------------------------------------
        // Deploy rollup contracts
        address rollupAddressManager = deployRollupContracts(sharedAddressManager, contractOwner);
    
        address taikoL1Addr = AddressManager(rollupAddressManager).getAddress(
            uint64(block.chainid), "taiko"
        );
        addressNotNull(taikoL1Addr, "taikoL1Addr");
        TaikoL1 taikoL1 = TaikoL1(payable(taikoL1Addr));
        
    }

    function deploySharedContracts(address owner) internal returns (address sharedAddressManager) {
        addressNotNull(owner, "owner");

        sharedAddressManager = address(0);// Dani: Can be set tho via ENV var, for now, for anvil, easy to just deploy every time
        if (sharedAddressManager == address(0)) {
            sharedAddressManager = deployProxy({
                name: "shared_address_manager",
                impl: address(new AddressManager()),
                data: abi.encodeCall(AddressManager.init, (owner))
            });
        }

        //dataToFeed = abi.encodeCall(TaikoToken.init, ("TAIKO", "TAIKO", MAINNET_CONTRACT_OWNER));
        address taikoToken = address(0); // Later on use this as env. var since already deployed (on testnets): vm.envAddress("TAIKO_TOKEN");
        if (taikoToken == address(0)) {
            taikoToken = deployProxy({
                name: "taiko_token",
                impl: address(new TaikoToken()),
                data: abi.encodeCall(TaikoToken.init, (MAINNET_CONTRACT_OWNER, MAINNET_CONTRACT_OWNER)),
                registerTo: sharedAddressManager
            });
        }

    }

function deployRollupContracts(
        address _sharedAddressManager,
        address owner
    )
        internal
        returns (address rollupAddressManager)
    {
        addressNotNull(_sharedAddressManager, "sharedAddressManager");
        addressNotNull(owner, "owner");

        rollupAddressManager = deployProxy({
            name: "rollup_address_manager",
            impl: address(new AddressManager()),
            data: abi.encodeCall(AddressManager.init, (owner))
        });

        // ---------------------------------------------------------------
        // Register shared contracts in the new rollup
        copyRegister(rollupAddressManager, _sharedAddressManager, "taiko_token");

        deployProxy({
            name: "taiko",
            impl: address(new TaikoL1()),
            data: abi.encodeCall(
                TaikoL1.init,
                (
                    owner,
                    rollupAddressManager,
                    vm.envBytes32("L2_GENESIS_HASH")
                )
            ),
            registerTo: rollupAddressManager
        });

        /* Deploy ChainProver */
        deployProxy({
                name: "chain_prover",
                impl: address(new ChainProver()),
                data: abi.encodeCall(ChainProver.init, (MAINNET_CONTRACT_OWNER, rollupAddressManager)),
                registerTo: rollupAddressManager
        });

        /* All tiers mocked */
        address verifier1 = deployProxy({
            name: "tier_sgx1",
            impl: address(new MockSgxVerifier()),
            data: abi.encodeCall(MockSgxVerifier.init, (MAINNET_CONTRACT_OWNER, rollupAddressManager)),
            registerTo: rollupAddressManager
        });
        address verifier2 = deployProxy({
            name: "tier_sgx2",
            impl: address(new MockSgxVerifier()),
            data: abi.encodeCall(MockSgxVerifier.init, (MAINNET_CONTRACT_OWNER, rollupAddressManager)),
            registerTo: rollupAddressManager
        });
        address verifier3 = deployProxy({
            name: "tier_sgx3",
            impl: address(new MockSgxVerifier()),
            data: abi.encodeCall(MockSgxVerifier.init, (MAINNET_CONTRACT_OWNER, rollupAddressManager)),
            registerTo: rollupAddressManager
        });

        /* Deploy VerifierRegistry */
        address vieriferRegistry = deployProxy({
                name: "verifier_registry",
                impl: address(new VerifierRegistry()),
                data: abi.encodeCall(VerifierRegistry.init, (MAINNET_CONTRACT_OWNER, rollupAddressManager)),
                registerTo: rollupAddressManager
            });

        // Add those 3 to verifier registry
        VerifierRegistry(vieriferRegistry).addVerifier(verifier1, "sgx1");
        VerifierRegistry(vieriferRegistry).addVerifier(verifier2, "sgx2");
        VerifierRegistry(vieriferRegistry).addVerifier(verifier3, "sgx3");

    }
    function addressNotNull(address addr, string memory err) private pure {
        require(addr != address(0), err);
    }

}