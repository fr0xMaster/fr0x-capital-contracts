// SPDX-License-Identifier: CC-BY-NC-ND-4.0 (Creative Commons Attribution Non Commercial No Derivatives 4.0 International)
/* solhint-disable var-name-mixedcase */
/* solhint-disable func-name-mixedcase */
/* solhint-disable  private-vars-leading-underscore */

pragma solidity 0.8.20;

import "forge-std/Test.sol";
import "../src/Fr0x.sol";

contract Fr0xTest is Test {
    uint256 public fantomFork;
    Fr0x public fr0x;

    // GLOBAL
    address public TREASURY = makeAddr("TREASURY");
    address public MARKETING_DEV = makeAddr("MARKETING_DEV");
    address public deployer = 0x15cB5F1463467289028949bCca68C246f4295c15;
    address public myLedger = makeAddr("myLedger");
    address public bob = makeAddr("bob");
    address public alice = makeAddr("alice");
    uint256 public TODAY = 1703462400;

    //FLOW
    //1 - Add 1010 FTM to deployer address
    //2 - Deploy Contract with deployer
    //3 - Trigger openTrading Function avec msg.value de 1000FTM et address de la ledger en param
    //3-5 - Achete avec slippage de 10% 2% du supply avec le wallet a stella et avec ma ledger
    //5 - Lock LP token avec la Ledger pendant 1 an sur Team.finance
    //6 - Renouce Ownership avec Deployer

    function setUp() public {
        string memory FANTOM_RPC_URL = vm.envString("FANTOM_RPC_URL");
        fantomFork = vm.createFork(FANTOM_RPC_URL);
        vm.selectFork(fantomFork);
        vm.warp(TODAY);
        vm.startPrank(deployer);
        fr0x = new Fr0x(TREASURY, MARKETING_DEV);

        vm.deal(alice, 10_000 ether);
        vm.deal(deployer, 1_000 ether);
        vm.deal(bob, 10_000 ether);
    }

    function test_Check_SupplyIsOwnedByContract() public {
        uint256 supply = fr0x.totalSupply();
        assertEq(supply, fr0x.TOTAL_SUPPLY());
        assertEq(supply, fr0x.balanceOf(address(fr0x)));
    }

    function test_Check_OwnerIsDeployerAtCreation() public {
        assertEq(fr0x.owner(), deployer);
    }

    function test_Check_LimtsAndThreeSold() public {
        assertEq(fr0x.tradeLimit(), (fr0x.totalSupply() * 2) / 100); // 2%
        assertEq(fr0x.walletLimit(), (fr0x.totalSupply() * 2) / 100); // 2%
        assertEq(fr0x.feeSwapThreshold(), (fr0x.totalSupply() * 5) / 10000); // 2%
    }

    function test_revert_OpenTradingButLessThan1000FTMOnContract() public {
        vm.expectRevert("Need 1000 FTM to Open Trading");
        fr0x.openTrading(myLedger);
    }

    function test_Check_OpenTrading() public {
        fr0x.openTrading{value: 1000 ether}(myLedger);
        assertEq(fr0x.tradingEnabled(), true);
        assertGe(IERC20(fr0x.uniswapV2Pair()).totalSupply(), IERC20(fr0x.uniswapV2Pair()).balanceOf(myLedger));
        emit log_named_uint("lp balance of my Ledger", IERC20(fr0x.uniswapV2Pair()).balanceOf(myLedger));
    }

    /*


    Check Swap trigger fees
    Check limits are used if block timestamp < 48h after deploiement
    Check if limits are not used if block timestamp > 48h after deploiement
    Check fees are sent in FTM form to Marketing Wallet and Treasury
    Check If transfer between two address dont trigger fees

    */
}
