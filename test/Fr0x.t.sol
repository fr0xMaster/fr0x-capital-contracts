// SPDX-License-Identifier: CC-BY-NC-ND-4.0 (Creative Commons Attribution Non Commercial No Derivatives 4.0 International)
/* solhint-disable var-name-mixedcase */
/* solhint-disable func-name-mixedcase */
/* solhint-disable  private-vars-leading-underscore */

pragma solidity 0.8.20;

import {IUniswapV2Pair} from "@uniswap-core/contracts/interfaces/IUniswapV2Pair.sol";
import {IUniswapV2Router02} from "@uniswap-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

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
    address public wojak = makeAddr("wojak");

    uint256 public TODAY = 1703462400;
    address public wftmToken = 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83;

    //FLOW
    //0 - Create wallet for devmarketing and treasruy on ledger
    //1 - Add 1010 FTM to deployer address sur metamask
    //2 - Deploy Contract with deployer et en parametre
    //3 - Trigger openTrading Function avec msg.value de 1000FTM et address de la ledger en param
    //3-5 - Achete max 2.5% du supply avec le wallet a stella et avec ma ledger
    //5 - Lock LP token avec la Ledger pendant 1 an sur Team.finance
    //6 - Renouce Ownership avec Deployer

    function setUp() public {
        string memory FANTOM_RPC_URL = vm.envString("FANTOM_RPC_URL");
        fantomFork = vm.createFork(FANTOM_RPC_URL);
        vm.selectFork(fantomFork);
        vm.warp(TODAY);
        vm.deal(deployer, 10_000 ether);
        vm.deal(alice, 20_000 ether);
        vm.deal(bob, 20_000 ether);
        vm.deal(wojak, 20_000 ether);

        vm.startPrank(deployer);
        fr0x = new Fr0x(TREASURY, MARKETING_DEV);
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
        assertEq(fr0x.tradeLimit(), (fr0x.totalSupply() * 10) / 1000); // 1%
        assertEq(fr0x.walletLimit(), (fr0x.totalSupply() * 10) / 1000); // 1%
        assertEq(fr0x.feeSwapThreshold(), (fr0x.totalSupply() * 5) / 10000); // 0.05%
    }

    function test_revert_OpenTradingButLessThan1000FTMOnContract() public {
        vm.expectRevert("Need 2000 FTM to Open Trading");
        fr0x.openTrading(myLedger);
    }

    function test_Check_OpenTrading() public {
        fr0x.openTrading{value: 2000 ether}(myLedger);
        assertEq(fr0x.tradingEnabled(), true);
        assertGe(IERC20(fr0x.uniswapV2Pair()).totalSupply(), IERC20(fr0x.uniswapV2Pair()).balanceOf(myLedger));
    }

    function test_Check_SwapTriggerFees() public {
        fr0x.openTrading{value: 2000 ether}(myLedger);
        vm.stopPrank();
        vm.startPrank(alice);
        uint256 aliceBalanceBefore = fr0x.balanceOf(alice);
        uint256 contractBalanceBefore = fr0x.balanceOf(address(fr0x));
        assertEq(aliceBalanceBefore, 0);
        assertEq(contractBalanceBefore, 0);

        address[] memory path = new address[](2);
        path[0] = wftmToken;
        path[1] = address(fr0x);
        // make the swap
        IUniswapV2Router02(fr0x.uniswapV2Router()).swapExactETHForTokensSupportingFeeOnTransferTokens{value: 20 ether}(
            20 ether, path, alice, block.timestamp
        );
        uint256 aliceBalanceAfter = fr0x.balanceOf(alice);
        uint256 contractBalanceAfter = fr0x.balanceOf(address(fr0x));
        assertGt(aliceBalanceAfter, aliceBalanceBefore);
        assertGt(contractBalanceAfter, contractBalanceBefore);
    }

    function test_Check_SwapBackAlsoTriggerFees() public {
        fr0x.openTrading{value: 2000 ether}(myLedger);
        vm.stopPrank();
        vm.startPrank(alice);
        // make the swap
        address[] memory path = new address[](2);
        path[0] = wftmToken;
        path[1] = address(fr0x);
        IUniswapV2Router02(fr0x.uniswapV2Router()).swapExactETHForTokensSupportingFeeOnTransferTokens{value: 2 ether}(
            2 ether, path, alice, block.timestamp
        );
        uint256 aliceBalanceAfterFirstSwap = fr0x.balanceOf(alice);
        uint256 contractBalanceAfterFirstSwap = fr0x.balanceOf(address(fr0x));
        address[] memory pathBack = new address[](2);
        pathBack[0] = address(fr0x);
        pathBack[1] = wftmToken;
        fr0x.approve(address(fr0x.uniswapV2Router()), aliceBalanceAfterFirstSwap);
        // make the swap
        IUniswapV2Router02(fr0x.uniswapV2Router()).swapExactTokensForETHSupportingFeeOnTransferTokens(
            aliceBalanceAfterFirstSwap,
            0, // accept any amount of ETH
            pathBack,
            alice,
            block.timestamp
        );
        uint256 aliceBalanceAfterSwapBack = fr0x.balanceOf(alice);
        uint256 contractBalanceAfterSwapBack = fr0x.balanceOf(address(fr0x));
        assertEq(aliceBalanceAfterSwapBack, 0);
        assertGt(contractBalanceAfterSwapBack, contractBalanceAfterFirstSwap);
    }

    function test_Check_NoLimitsAfter48Hours() public {
        fr0x.openTrading{value: 2000 ether}(myLedger);
        vm.warp(TODAY + 2 days + 1);
        vm.stopPrank();
        vm.startPrank(alice);
        address[] memory path = new address[](2);
        path[0] = wftmToken;
        path[1] = address(fr0x);
        IUniswapV2Router02(fr0x.uniswapV2Router()).swapExactETHForTokensSupportingFeeOnTransferTokens{value: 2000 ether}(
            2000 ether, path, alice, block.timestamp
        );
        assertGt(fr0x.balanceOf(alice), fr0x.walletLimit());
    }

    function test_Check_TransferBetweenTwoWalletsDontTriggerFees() public {
        fr0x.openTrading{value: 2000 ether}(myLedger);
        vm.stopPrank();
        vm.startPrank(alice);
        uint256 aliceBalanceBefore = fr0x.balanceOf(alice);
        assertEq(aliceBalanceBefore, 0);
        address[] memory path = new address[](2);
        path[0] = wftmToken;
        path[1] = address(fr0x);
        // make the swap
        IUniswapV2Router02(fr0x.uniswapV2Router()).swapExactETHForTokensSupportingFeeOnTransferTokens{value: 20 ether}(
            20 ether, path, alice, block.timestamp
        );
        uint256 aliceBalanceAfter = fr0x.balanceOf(alice);
        uint256 bobBalanceBeforeTransfer = fr0x.balanceOf(bob);
        assertGt(aliceBalanceAfter, aliceBalanceBefore);
        assertEq(bobBalanceBeforeTransfer, 0);

        fr0x.transfer(bob, aliceBalanceAfter);
        uint256 bobBalanceAfterTransfer = fr0x.balanceOf(bob);
        uint256 aliceBalanceAfterTransfer = fr0x.balanceOf(alice);
        assertEq(aliceBalanceAfterTransfer, 0);
        assertEq(aliceBalanceAfter, bobBalanceAfterTransfer);
    }

    function test_Check_SwapThreesoldTriggerSentToTreasuryAndMarketingDevWallet() public {
        fr0x.openTrading{value: 2000 ether}(myLedger);
        vm.stopPrank();
        vm.startPrank(alice);
        uint256 aliceBalanceBeforeFirstSwap = fr0x.balanceOf(alice);
        uint256 contractBalanceBeforeFirstSwap = fr0x.balanceOf(address(fr0x));
        uint256 treasuryBalanceBeforeFirstSwap = fr0x.balanceOf(TREASURY);
        uint256 marketingDevBalanceBeforeFirstSwap = fr0x.balanceOf(MARKETING_DEV);

        assertEq(aliceBalanceBeforeFirstSwap, 0);
        assertEq(contractBalanceBeforeFirstSwap, 0);
        assertEq(treasuryBalanceBeforeFirstSwap, 0);
        assertEq(marketingDevBalanceBeforeFirstSwap, 0);

        address[] memory path = new address[](2);
        path[0] = wftmToken;
        path[1] = address(fr0x);
        IUniswapV2Router02(fr0x.uniswapV2Router()).swapExactETHForTokensSupportingFeeOnTransferTokens{value: 20 ether}(
            20 ether, path, alice, block.timestamp
        );

        uint256 aliceBalanceAfterFirstSwap = fr0x.balanceOf(alice);
        uint256 contractBalanceAfterFirstSwap = fr0x.balanceOf(address(fr0x));
        uint256 treasuryBalanceAfterFirstSwap = fr0x.balanceOf(TREASURY);
        uint256 marketingDevBalanceAfterFirstSwap = fr0x.balanceOf(MARKETING_DEV);

        assertGt(aliceBalanceAfterFirstSwap, aliceBalanceBeforeFirstSwap);
        assertGt(contractBalanceAfterFirstSwap, contractBalanceBeforeFirstSwap);
        assertEq(treasuryBalanceAfterFirstSwap, 0);
        assertEq(marketingDevBalanceAfterFirstSwap, 0);

        vm.stopPrank();
        vm.startPrank(bob);
        uint256 bobBalanceBeforeSecondSwap = fr0x.balanceOf(bob);
        address[] memory pathSecondSwap = new address[](2);
        pathSecondSwap[0] = wftmToken;
        pathSecondSwap[1] = address(fr0x);
        IUniswapV2Router02(fr0x.uniswapV2Router()).swapExactETHForTokensSupportingFeeOnTransferTokens{value: 20 ether}(
            20 ether, path, bob, block.timestamp
        );

        uint256 bobBalanceAfterSecondSwap = fr0x.balanceOf(bob);
        uint256 contractBalanceAfterSecondSwap = fr0x.balanceOf(address(fr0x));
        assertGt(bobBalanceAfterSecondSwap, bobBalanceBeforeSecondSwap);
        assertGt(contractBalanceAfterSecondSwap, contractBalanceAfterFirstSwap);
        assertLt(bobBalanceAfterSecondSwap, aliceBalanceAfterFirstSwap);

        vm.stopPrank();
        vm.startPrank(wojak);
        uint256 wojakBalanceBeforeThirdSwap = fr0x.balanceOf(wojak);

        address[] memory pathThirdSwap = new address[](2);
        pathThirdSwap[0] = wftmToken;
        pathThirdSwap[1] = address(fr0x);
        // make the swap
        IUniswapV2Router02(fr0x.uniswapV2Router()).swapExactETHForTokensSupportingFeeOnTransferTokens{value: 20 ether}(
            20 ether, path, wojak, block.timestamp
        );

        uint256 wojakBalanceAfterThirdSwap = fr0x.balanceOf(wojak);
        uint256 contractBalanceAfterThirdSwap = fr0x.balanceOf(address(fr0x));
        assertGt(wojakBalanceAfterThirdSwap, wojakBalanceBeforeThirdSwap);
        assertGt(contractBalanceAfterThirdSwap, contractBalanceAfterSecondSwap);

        vm.stopPrank();
        vm.startPrank(alice);

        address[] memory pathBack = new address[](2);
        pathBack[0] = address(fr0x);
        pathBack[1] = wftmToken;
        fr0x.approve(address(fr0x.uniswapV2Router()), aliceBalanceAfterFirstSwap);
        // make the swap
        IUniswapV2Router02(fr0x.uniswapV2Router()).swapExactTokensForETHSupportingFeeOnTransferTokens(
            aliceBalanceAfterFirstSwap,
            0, // accept any amount of ETH
            pathBack,
            alice,
            block.timestamp
        );
        uint256 aliceBalanceAfterFourthSwap = fr0x.balanceOf(alice);
        assertEq(aliceBalanceAfterFourthSwap, 0);
        uint256 contractBalanceAfterFourthSwap = fr0x.balanceOf(address(fr0x));
        assertEq(contractBalanceAfterFourthSwap, 0);

        assertGt(MARKETING_DEV.balance, 0);
        assertGt(TREASURY.balance, 0);
        assertGt(TREASURY.balance, MARKETING_DEV.balance);
    }
}
