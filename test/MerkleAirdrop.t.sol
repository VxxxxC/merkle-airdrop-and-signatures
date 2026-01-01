// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {MerkleAirdrop} from "../src/MerkleAirdrop.sol";
import {BagelToken} from "../src/BagelToken.sol";

contract MerkleAirdropTest is Test {
    bytes32 public constant ROOT = 0xb1e815a99ee56f7043ed94e7e2316238187a59d85c211d06f9be7c5f94424aec;
    uint256 public constant AmountToClaim = 25 * 1e18;

    bytes32 public proofOne = 0x9e10faf86d92c4c65f81ac54ef2a27cc0fdf6bfea6ba4b1df5955e47f187115b;
    bytes32 public proofTwo = 0x8c1fd7b608678f6dfced176fa3e3086954e8aa495613efcd312768d41338ceab;
    bytes32[] public PROOF = [proofOne, proofTwo]; // WARN: This is just copied from the output.json for testing only!!

    MerkleAirdrop public airdrop;
    BagelToken public token;

    address user;
    uint256 userPrivateKey;

    function setUp() public {
        token = new BagelToken();
        airdrop = new MerkleAirdrop(ROOT, token);

        (user, userPrivateKey) = makeAddrAndKey("user"); // NOTE: different of `makeAddr`, `makeAddrAndKey` will also return the private key of the address
    }

    // function testGetUser() public {
    //     console.log("user address:", user);
    //     console.log("user private key:", userPrivateKey);
    // }

    function testUseCanClaim() public {
        uint256 startingBalance = token.balanceOf(user);
        console.log("user starting balance:", startingBalance);

        vm.startPrank(user);
        airdrop.claim(user, AmountToClaim, PROOF);

        uint256 endingBalance = token.balanceOf(user);
        console.log("user ending balance:", endingBalance);

        assertEq(endingBalance - startingBalance, AmountToClaim);
    }
}
