// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {IERC20, SafeERC20} from "@openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";
import {MerkleProof} from "@openzeppelin-contracts/utils/cryptography/MerkleProof.sol";

contract MerkleAirdrop {
    using SafeERC20 for IERC20; // NOTE: `using` syntax means we can call SafeERC20 functions on IERC20 type

    // some list of addresses
    // allow someone in the list to claim ERC20 token
    address[] claimers;
    bytes32 private immutable i_merkleRoot;
    IERC20 private immutable i_airdropToken;

    mapping(address claimer => bool claimed) private s_hasClaimed;

    event Claim(address indexed account, uint256 amount);

    error MerkleAirdrop__InvalidProof();
    error MerkleAirdrop__AlreadyClaimed();

    constructor(bytes32 merkleRoot, IERC20 airdropToken) {
        i_merkleRoot = merkleRoot;
        i_airdropToken = airdropToken;
    }

    // WARN: This function need to be follow CEI(Checks-Effects-Interactions) pattern to prevent reentrancy attack
    function claim(address account, uint256 amount, bytes32[] calldata merkleProof) external {
        // NOTE: CHECKS
        if (s_hasClaimed[account] == true) {
            revert MerkleAirdrop__AlreadyClaimed();
        }

        // calculate using the account and the amount , the hash -> leaf node
        // WARN: leaf cannot be bytes64 or longer , also don't use other hash function than keccak256 , as mentioned in @openzeppelin warning in MerkleProof
        // also keccak256 hashed the leaf twice time for prevent preimage attack
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(account, amount))));
        if (!MerkleProof.verify(merkleProof, i_merkleRoot, leaf)) {
            revert MerkleAirdrop__InvalidProof();
        }
        emit Claim(account, amount);
        i_airdropToken.safeTransfer(account, amount);
    }
}
