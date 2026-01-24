// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {IERC20, SafeERC20} from "@openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";
import {MerkleProof} from "@openzeppelin-contracts/utils/cryptography/MerkleProof.sol";
import {ScriptHelper} from "@murky/script/common/ScriptHelper.sol";
import {EIP712} from "@openzeppelin-contracts/utils/cryptography/EIP712.sol";
import {ECDSA} from "@openzeppelin-contracts/utils/cryptography/ECDSA.sol";
import {console} from "forge-std/console.sol";

contract MerkleAirdrop is ScriptHelper, EIP712 {
    using SafeERC20 for IERC20; // NOTE: `using` syntax means we can call SafeERC20 functions on IERC20 type

    struct AirdropClaim {
        address account;
        uint256 amount;
    }

    // some list of addresses
    // allow someone in the list to claim ERC20 token
    address[] claimers;
    bytes32 private immutable i_merkleRoot;
    IERC20 private immutable i_airdropToken;
    bytes32 private constant MESSAGE_TYPEHASH = keccak256("AirdropClaim(address account, uint256 amount)");

    mapping(address claimer => bool claimed) private s_hasClaimed;

    event Claim(address indexed account, uint256 amount);

    error MerkleAirdrop__InvalidProof();
    error MerkleAirdrop__AlreadyClaimed();
    error MerkleAirdrop__InvalidSignature();

    constructor(bytes32 merkleRoot, IERC20 airdropToken) EIP712("MerkleAirop", "1") {
        i_merkleRoot = merkleRoot;
        i_airdropToken = airdropToken;
    }

    // WARN: This function need to be follow CEI(Checks-Effects-Interactions) pattern to prevent reentrancy attack
    function claim(address account, uint256 amount, bytes32[] calldata merkleProof, uint8 v, bytes32 r, bytes32 s)
        external
    {
        // NOTE: CHECKS :
        if (s_hasClaimed[account] == true) {
            revert MerkleAirdrop__AlreadyClaimed();
        }

        // check the signature
        bytes32 messageDigest = getMessageHash(account, amount);
        if (!_isValidSignature(account, messageDigest, v, r, s)) {
            revert MerkleAirdrop__InvalidSignature();
        }

        // NOTE: EFFECTS:
        // calculate using the account and the amount , the hash -> leaf node
        // WARN: leaf cannot be bytes64 or longer , also don't use other hash function than keccak256 , as mentioned in @openzeppelin warning in MerkleProof
        // also keccak256 hashed the leaf twice time for prevent preimage attack
        // PERFORMANCE: Must match the encoding in MakeMerkle.s.sol - convert to bytes32 to match ltrim64(abi.encode(bytes32[]))
        bytes32 leaf =
            keccak256(bytes.concat(keccak256(abi.encode(bytes32(uint256(uint160(account))), bytes32(amount)))));
        console.logBytes32(merkleProof[0]);
        console.logBytes32(merkleProof[1]);
        console.logBytes32(i_merkleRoot);
        console.logBytes32(leaf);
        if (!MerkleProof.verify(merkleProof, i_merkleRoot, leaf)) {
            revert MerkleAirdrop__InvalidProof();
        }

        // NOTE: INTERACTIONS:
        emit Claim(account, amount);
        i_airdropToken.safeTransfer(account, amount);
    }

    function getMerkleRoot() external view returns (bytes32) {
        return i_merkleRoot;
    }

    function getAirdropToken() external view returns (IERC20) {
        return i_airdropToken;
    }

    function getMessageHash(address account, uint256 amount) public view returns (bytes32) {
        return
            _hashTypedDataV4(keccak256(abi.encode(MESSAGE_TYPEHASH, AirdropClaim({account: account, amount: amount}))));
    }

    function _isValidSignature(address expectSigner, bytes32 digest, uint8 v, bytes32 r, bytes32 s)
        internal
        returns (bool)
    {
        (address signer,,) = ECDSA.tryRecover(digest, v, r, s);
        address account = address(bytes20(expectSigner));
        console.log("account :", account);
        address recoveredSigner = address(bytes20(signer));
        console.log("recoveredSigner :", recoveredSigner);
        return account == recoveredSigner;
    }
}
