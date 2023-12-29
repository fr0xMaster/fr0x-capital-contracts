// SPDX-License-Identifier: MIT
/* solhint-disable var-name-mixedcase */
/* solhint-disable func-param-name-mixedcase */
pragma solidity 0.8.19;

import "forge-std/Script.sol";
import "../src/Fr0x.sol";

contract Fr0xScript is Script {
    Fr0x public fr0x;

    address public TREASURY = 0x458E7E85960201f3a263B5011789F0e618aB6bCb;
    address public MARKETING_DEV = 0x32a678eE2FAD69dDA29C13E3048430382bd05A10;

    function setUp() public {}

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        fr0x = new Fr0x(TREASURY, MARKETING_DEV);

        vm.stopBroadcast();
        //To Deploy: source .env && forge script script/Fr0x.s.sol:Fr0xScript --rpc-url $FANTOM_RPC_URL --private-key $PRIVATE_KEY --broadcast
        //TO VERIFY : forge verify-contract --chain 250  --show-standard-json-input > Fr0x.json <ContractAddress> src/Fr0x.sol:Fr0x
        // After that, go to ftmscan to verify with standard.json
        // Trigger OpenTrading func with ledger address in param and 2000FTM
    }
}
