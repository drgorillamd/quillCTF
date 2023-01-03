// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;
//deployed goerli 0xf8e9327e38ceb39b1ec3d26f5fad09e426888e66

// cast storage 0xf8e9327e38ceb39b1ec3d26f5fad09e426888e66 2 --rpc-url $GOERLI
// cast storage 0xf8e9327e38ceb39b1ec3d26f5fad09e426888e66 7 --rpc-url $GOERLI
contract Confidential {
    string public firstUser = "ALICE"; // 0
    uint public alice_age = 24; // 1
	bytes32 private ALICE_PRIVATE_KEY; //2 - Super Secret Key: 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
    bytes32 public ALICE_DATA = "QWxpY2UK"; // 3
    bytes32 private aliceHash = hash(ALICE_PRIVATE_KEY, ALICE_DATA); // 4

    string public secondUser = "BOB"; // 5
    uint public bob_age = 21;   // 6
    bytes32 private BOB_PRIVATE_KEY; // 7 - Super Secret Key: 0x2a871d0798f97d79848a013d4936a73bf4cc922c825d33c1cf7073dff6d409c6
    bytes32 public BOB_DATA = "Qm9iCg"; // 8
    bytes32 private bobHash = hash(BOB_PRIVATE_KEY, BOB_DATA); // 9
		
	constructor() {}

    function hash(bytes32 key1, bytes32 key2) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(key1, key2));
    }

    function checkthehash(bytes32 _hash) public view returns(bool){
        require (_hash == hash(aliceHash, bobHash));
        return true;
    }
}