// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "../../TaikoData.sol";

/// @title LibPublicInput
/// @notice A library for handling hashing the so-called public input hash, used by sgx and zk
/// proofs.
/// @custom:security-contact security@taiko.xyz
library LibPublicInput {
    /// @notice Hashes the public input for the proof verification.
    /// @param _transitionHash The new state hash transition.
    /// @param _verifierContract The contract address which as current verifier.
    /// @param _newInstance The new instance address. For SGX it is the new signer address, for ZK
    /// this variable is not used and must have value address(0).
    /// @param _prover The prover address.
    /// @param _chainId The chain id.
    /// @return The public input hash.
    function hashPublicInputs(
        bytes32 _transitionHash,
        address _verifierContract,
        address _newInstance,
        address _prover,
        uint64 _chainId
    )
        internal
        pure
        returns (bytes32)
    {
        return keccak256(
            abi.encode(
                "VERIFY_PROOF", _chainId, _verifierContract, _transitionHash, _newInstance, _prover
            )
        );
    }
}
