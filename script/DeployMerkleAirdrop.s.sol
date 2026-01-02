// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {MerkleAirdrop} from "../src/MerkleAirdrop.sol";
import {BagelToken} from "../src/BagelToken.sol";
import {IERC20} from "@openzeppelin-contracts/token/ERC20/IERC20.sol";
import {ZkSyncChainChecker} from "@foundry-devops/src/ZkSyncChainChecker.sol";

contract DeployMerkleAirdrop is Script, ZkSyncChainChecker {
    bytes32 private s_merkleRoot = 0xb1e815a99ee56f7043ed94e7e2316238187a59d85c211d06f9be7c5f94424aec;
    uint256 private s_amountToAirdrop = 2500 * 1e18; // WARN: Match input.json: 2500 tokens, not 25!
    uint256 private s_amountToTransfer = s_amountToAirdrop * 4;

    function fun() external returns(MerkleAirdrop, BagelToken) {
        return deployMerkleAirdrop();
    }

    function deployMerkleAirdrop() public returns (MerkleAirdrop, BagelToken) {
        vm.startBroadcast();
        BagelToken token = new BagelToken();
        MerkleAirdrop airdrop = new MerkleAirdrop(
            s_merkleRoot,
            IERC20(address(token))
        );

        token.mint(token.owner(), s_amountToAirdrop * 4); // Mint enough tokens for 4 users
        token.transfer(address(airdrop), s_amountToTransfer); //

        vm.stopBroadcast();
        return (airdrop, token);
    }
}