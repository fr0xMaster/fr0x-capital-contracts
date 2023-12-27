// SPDX-License-Identifier: MIT
/* solhint-disable var-name-mixedcase */
/* solhint-disable func-param-name-mixedcase */
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import {Fr0x} from "../src/Fr0x.sol";

contract Fr0xScript is Script {
/* 
    FrenBondFT public frenBondFT;

    //TODO FOR MAINNET VERSIION !!!!!!!!!!!!!!!!!!!
    // Create safe for the team
    // Create a safe for the fee collector
    // Create a safe for the revShare
    // Deploy contraxct with de team safe

    address public PYTH; //PYTH ON BASE
    address public FT_CONTRACT; // FRIEND TECH ON BASE
    address public XFB; //XFB ON BASE
    bytes32 public PYTH_ETHUSD_PRICE_ID; //ETHUSD PRICE ID MAINNET
    uint256 public MATURITY = 1 days; //Bond maturity time
    uint256 public BETTING_TIME = 1 days / 6; //Time to place bets
    address[] public KEY_INDEX = [
        0xF0a5a3b09a919c7Fe826ea0D9482e8D377952821,
        0xA8BA11Db2901905C6Ab49c1c86E69FD22081F68A,
        0x1b546a13875C83Db8bab7Ea4DF760B13019a976c,
        0x9C1c9027F2E9194f00F8F732DE9f36FDC1E225D6,
        0x3EE9EdA7d7AE365b47BE8bFE67e07E27522aaf6A,
        0x1f5b68B914F7ad1AFCA4528B357827def2500F38
    ]; // CBB0FE, bitgoten,Saudi_Bidor,SmartBizon, SheepOfBitmex, Gatiencnts -  (CBB Cartel) Keys.
    address public FEES_COLLECTOR; //CREATE FEE COLLECTOR ? CHECK NEW IMPLEMENTATIon
    address public REV_SHARE; //STAKING CONTRACT
    uint256 public VARIATION_NUMERATOR = 5; //To calculate variation when LAST_VARIATION == 0;

    function setUp() public {}

    function run() external {
        //// PUT THE PRIVATE KEY OF THE SAFE CREATED FOR THE MAINNET VERSION
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        frenBondFT =
        new FrenBondFT(PYTH,FT_CONTRACT, XFB ,PYTH_ETHUSD_PRICE_ID, MATURITY,BETTING_TIME,KEY_INDEX, FEES_COLLECTOR, REV_SHARE, VARIATION_NUMERATOR);
        vm.stopBroadcast();
        //To Deploy: source .env && forge script script/Base/FrenBondFTDeployer.s.sol:FrenBondFTDeployer --private-key $PRIVATE_KEY --broadcast
        //TO VERIFY : forge verify-contract --chain 8453  --show-standard-json-input > FrenBondFT.json <ContractAddress> src/FrenBondFT.sol:FrenBondFT
        // After that, go to basescan to verify with standard.json
        // DONT FORGET TO ADD THIS FRENBONDV1 CONTFRACT ADDRESS TO LIST OF MINTERS IN FRENBONDTOKEN CONTRACT;
    }
*/
}
