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

interface IWFTM is IERC20 {
    function deposit() external payable;
    function withdraw(uint256) external;
}

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
    address public wftmToken = 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83;
    IWFTM public immutable WFTM = IWFTM(wftmToken);

    //FLOW
    //0 - Create wallet for devmarketing and treasruy on ledger
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
        vm.deal(deployer, 1_000 ether);
        vm.deal(alice, 20_000 ether);
        vm.deal(bob, 20_000 ether);

        vm.startPrank(alice);
        WFTM.deposit{value: 10_000 ether}();
        vm.stopPrank();
        vm.startPrank(bob);
        WFTM.deposit{value: 10_000 ether}();
        vm.stopPrank();
        vm.startPrank(deployer);
        fr0x = new Fr0x(TREASURY, MARKETING_DEV);
    }

    /*

    
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
    }
    */
    function test_Check_SwapTriggerFees() public {
        fr0x.openTrading{value: 1000 ether}(myLedger);
        vm.stopPrank();
        vm.startPrank(alice);
        assertEq(WFTM.balanceOf(alice), 10_000 ether);
        uint256 fr0xBalanceOfAliceBefore = fr0x.balanceOf(alice);
        assertEq(fr0xBalanceOfAliceBefore, 0);
        emit log_named_uint("fr0x contract balance before", fr0x.balanceOf(address(fr0x)));
        emit log_named_uint("fr0xBalance before", fr0xBalanceOfAliceBefore);

        address[] memory path = new address[](2);
        path[0] = wftmToken;
        path[1] = address(fr0x);
        // make the swap
        IUniswapV2Router02(fr0x.uniswapV2Router()).swapExactETHForTokensSupportingFeeOnTransferTokens{value: 20 ether}(
            20 ether, path, alice, block.timestamp
        );
        uint256 fr0xBalanceOfAliceAfter = fr0x.balanceOf(alice);
        emit log_named_uint("fr0xBalance receive for 50 FTM", fr0xBalanceOfAliceAfter);
        emit log_named_uint("fr0x contract balance after", fr0x.balanceOf(address(fr0x)));

        assertGt(fr0xBalanceOfAliceAfter, fr0xBalanceOfAliceBefore);

        /*
        // SWAP BACK

        address[] memory pathSwapback = new address[](2);
        pathSwapback[0] = address(fr0x);
        pathSwapback[1] = wftmToken;

        fr0x.approve(address(fr0x.uniswapV2Router()), fr0xBalanceOfAliceAfter);
        // make the swap
        IUniswapV2Router02(fr0x.uniswapV2Router()).swapExactTokensForETHSupportingFeeOnTransferTokens(
            fr0xBalanceOfAliceAfter,
            0, // accept any amount of ETH
            pathSwapback,
            address(this),
            block.timestamp
        );

        uint256 fr0xBalanceOfAliceAfterSwapBack = fr0x.balanceOf(alice);
        emit log_named_uint("fr0xBalanceOfAliceAfterSwapBack", fr0xBalanceOfAliceAfterSwapBack);


        

        

        
         */
    }

    /*


    Check Swap trigger fees

    Check limits are used if block timestamp < 48h after deploiement
    Check if limits are not used if block timestamp > 48h after deploiement
    Check fees are sent in FTM form to Marketing Wallet and Treasury
    Check If transfer between two address dont trigger fees

    */
}
