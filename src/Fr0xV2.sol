// SPDX-License-Identifier: MIT
/* solhint-disable var-name-mixedcase */
/* solhint-disable func-name-mixedcase */
/* solhint-disable  private-vars-leading-underscore */
pragma solidity 0.8.19;

/**
 * fr0x Capital ($fr0x)
 * Website: https://fr0x.capital
 * Telegram: https://t.me/fr0xCapital
 * Twitter: https://twitter.com/fr0xCapital
 * ....................................................................................................
 * .........................................''''''''''''''''''''.......................................
 * ..................................''''''''''''''''''''''''''''''''''................................
 * ..............................''''''''',,,,,,,,,,,,,,,,,,,,,,,''''''''''............................
 * ...........................''''''',,,,,,,,,;;;;;;;;;;;;;;,,,,,,,,,,''''''''.........................
 * .........................'''''',,,,,;;;::cccllllllllllllllcc:::;;;,,,,,''''''.......................
 * ........................''''',,,;;:ldxO0KXXXXXNNNNNNNNNNXXXXKK0Okxol:;,,,'''''......................
 * ......................''''',,,;cokKXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWX0xl;,,,''''.....................
 * ......................'''',,;cxKNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXxc;,,''''....................
 * .....................'''',,;ckWMMMMMMMWNXKK000000000OOOOOOOOOOO0KNWMMMMWOc;,,''''...................
 * ....................''''',,;oKMMMMMWN0xolcccccccc:cccc:::::::::ccoxOXWMMNk:,,,''''..................
 * ....................'''',,,:xNMMMN0xoc::::::::::::ccc:::::::;;;:::::oOWMMKl;,,''''..................
 * ....................'''',,;:kNMMNkc::::::;:::::cdO000Oxc:;;;;;;;;;;;:l0WMXd;,,''''..................
 * ....................'''',,,:xNMWKo::;;;:;;;;;;:xNMMMMMXd:;;;;;;;;;;;;ckWMNd;,,''''..................
 * ....................'''',,,;oXMMKo::;;;;;;;;;;:dKWWWWWKo:;;;;;;;;;;;;:kNWKo;,,''''..................
 * ....................''''',,;ckNMW0o::;;;;;;;;;;:lxkkxdl:;;;;;;;;;;;;;cOWNk:,,'''''..................
 * ....................''''',,,;ckNMWXkl::;;;;;;;;;;;;;;;;;;;;;;;;;;;;;cxXNOc;,,'''''..................
 * .....................'''',,,,;:d0NWWX0xolc:::::::::::;;;;;;;;:::cldkKXKd:;,,,'''''..................
 * .....................''''',,,,;;cok0XNNNXK0OOOOOOOOOOkkkkkkkOO0KKKK0koc;,,,,,''''...................
 * .....................''''',,,,,,;;;:codxxkkOOO0000000000OOOOkkxxdlc:;;;,,,,,'''''...................
 * .....................''''',,,;;;;;;;;;;;;;;::::::::::::::;;;;;;;;;;;;;,,,,,,'''''...................
 * .....................''''',;dkxl:;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;:ldo:,'''''...................
 * .....................''''',c0WWN0xl:;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;:clx0XWXo,,''''...................
 * .....................''''',;dKWMMWX0dl:;;;;;;;;;;;;;;;;;;;;;;;;:cok0NWMMWKo,'''''...................
 * ......................''''',;cdOXNWMWXOdc::;;;;;;;;;;;;;;;:::ldkKNWMMWNKkl;,'''''...................
 * ......................'''''',,,;cok0NWWNKkdc::;;::;;;::::coxOXWMMMWNKko:;,,'''''....................
 * .......................'''''',,,,;;:lx0NWWNKOdlc:::::cldOKNWMMMWX0xo:;;,,,'''''.....................
 * ........................''''',,,,,;;;:cokKNWWNKOxdodk0XWMMMMWXOxl::;;,,,,,'''''.....................
 * ........................'''''',,,,;;;;:::ldOXWMMWNNWWMMMWNKOdlc:;;;;,,,,''''''......................
 * .........................''''',,,,;;;;;::ccoONMMMMMMMMMWKxlc::::;;;;,,,,'''''.......................
 * ........................'''''',,,,;;;::cox0XWMMMMWWWMMMWNKOdl:::;;;;,,,,'''''.......................
 * ........................''''',,,,;;:cok0NWMMMWNKOxxxOKNWMMWNKOdl:;;;,,,,'''''.......................
 * ........................'''',,,,;ldOKNWMMMWX0koc:::::clxOKNWMMWXOxl:;,,,''''''......................
 * .......................'''',,;cdOXWMMMWNKOdl::;;;;;;;;;;:coxOKNWMWX0xl:,,,'''''.....................
 * .......................''',:dOXWMMMWNKkoc:;;;;,,,,,,,,,,,;;;:cokKNWMWX0xl:,''''.....................
 * .......................''',lKWMMWN0ko:;;,,,,,,,,,,,,,,,,,,,,,,,;:ox0NWMWN0l,'''.....................
 * ........................'',lKWXOxl:;,,,,,,,''''''''''''''''',,,,,,;:lkKNWWk;''......................
 * ........................''';lo:;,,,''''''''''''''''''''''''''''''''',,:lxxl,'.......................
 * ..........................'''''''''''''''''''............'''''''''''''''''''........................
 * ................................''''''.........................'''''''..............................
 * ....................................................................................................
 */
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {IUniswapV2Factory} from "@uniswap-core/contracts/interfaces/IUniswapV2Factory.sol";
import {IUniswapV2Router02} from "@uniswap-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import {IEqualizerFactory} from "./interfaces/IEqualizerFactory.sol";
import {IEqualizerRouterV3} from "./interfaces/IEqualizerRouterV3.sol";

contract Fr0xV2 is ERC20, Ownable {
    uint256 public constant TOTAL_SUPPLY = 10_000_000_000 * 1e18;

    IUniswapV2Router02 public immutable uniswapV2Router;
    IEqualizerRouterV3 public immutable equalizerRouterV3;
    address public uniswapV2Pair;
    address public equalizerV3Pair;

    uint256 public feeSwapThreshold;
    uint256 public SELL_FEE = 500; // 5%
    uint256 public BUY_FEE = 500; // 5%

    address public TREASURY;
    address public DEVELOPMENT;
    address public MIGRATION;

    bool private _isSwapping;

    mapping(address => bool) public pools;
    mapping(address => bool) internal _exemptFromFees;

    error CannotRemoveDefaultPair();
    error MaxFees();

    struct Route {
        address from;
        address to;
        bool stable;
    }

    //TODO: Need to mint total supply and transfer at migration contract.
    //TODO: Need to add setter to add pool in pools
    //TODO: Need to add setter to add contract in _exemptFromFees
    //TODO: Need to add setter to handle change fees
    //TODO: Need to add setter to  change share of fees between TREASURY AND DEVELPMENT
    //TODO: make it compatible for biridge to axellar or layer zero
    /*
       1 - Deploy Migration Contract with a function who wiat an address for fro0x v2 and a state to tell Migration is ready
            - Migration contract can be trigger via this function if v2 is deployed and hava an address & Migration balance of v2 Token is TOTAL SUPPLY
       2 - Deploy FroxV2 with the address of Migration Contract and transfer TOTAL SUpply to V2
     */

    constructor(address _treasury, address _development, address _migration) ERC20("fr0xCapital", "fr0x") {
        uniswapV2Router = IUniswapV2Router02(0xF491e7B69E4244ad4002BC14e878a34207E38c29); //SpookySwap Router
        equalizerRouterV3 = IEqualizerRouterV3(0x33da53f731458d6Bc970B0C5FCBB0b3Db4AAa470); //Equalizer Router
        feeSwapThreshold = _applyBasisPoints(TOTAL_SUPPLY, 5); // 0.05%

        TREASURY = _treasury;
        DEVELOPMENT = _development;

        _exemptFromFees[owner()] = true;
        _exemptFromFees[address(this)] = true;
        _exemptFromFees[TREASURY] = true;
        _exemptFromFees[DEVELOPMENT] = true;

        _mint(_migration, TOTAL_SUPPLY);
        _approve(address(this), address(uniswapV2Router), TOTAL_SUPPLY);

        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint256).max);
        pools[address(uniswapV2Pair)] = true;

        equalizerV3Pair =
            IEqualizerFactory(equalizerRouterV3.factory()).createPair(address(this), equalizerRouterV3.weth(), false);
        IERC20(equalizerV3Pair).approve(address(equalizerRouterV3), type(uint256).max);
        pools[address(equalizerV3Pair)] = true;
    }

    receive() external payable {}

    function _transfer(address from, address to, uint256 amount) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        uint256 finalAmount = _chargeFees(from, to, amount);
        _handleFeeSwap(from, to);

        super._transfer(from, to, finalAmount);
    }

    function _chargeFees(address from, address to, uint256 amount) internal returns (uint256) {
        if (_isSwapping || _exemptFromFees[from] || _exemptFromFees[to]) {
            return amount;
        }

        uint256 fees = 0;
        if (pools[to] && SELL_FEE > 0) {
            fees = _applyBasisPoints(amount, SELL_FEE);
        } else if (pools[from] && BUY_FEE > 0) {
            fees = _applyBasisPoints(amount, BUY_FEE);
        }

        if (fees > 0) {
            super._transfer(from, address(this), fees);
        }

        return amount - fees;
    }

    function _handleFeeSwap(address from, address to) internal {
        bool canSwap = balanceOf(address(this)) >= feeSwapThreshold;

        // non-exempt sellers trigger fee swaps
        if (canSwap && !_isSwapping && !pools[from] && pools[to] && !_exemptFromFees[from]) {
            _isSwapping = true;
            _swapAndDistributeFees();
            _isSwapping = false;
        }
    }

    function _swapAndDistributeFees() internal {
        uint256 contractBalance = balanceOf(address(this));

        if (contractBalance == 0) {
            return;
        }

        if (contractBalance > feeSwapThreshold * 20) {
            contractBalance = feeSwapThreshold * 20;
        }

        _swapTokensForEth(contractBalance);

        uint256 feesForTreasury = _applyBasisPoints(address(this).balance, 7500); //75%
        uint256 feesForDevelopment = address(this).balance - feesForTreasury; //25%
        (bool sentToTreasury,) = TREASURY.call{value: feesForTreasury}("");
        require(sentToTreasury, "sent to treasury failed");
        (bool sentToMarketingDev,) = DEVELOPMENT.call{value: feesForDevelopment}("");
        require(sentToMarketingDev, "sent to Marketing/dev failed");
    }

    function setMarketingWallet(address _development) external {
        require(msg.sender == TREASURY, "Not authorized");
        DEVELOPMENT = _development;
    }

    function setTreasury(address _newTreasury) external {
        require(msg.sender == TREASURY, "Not authorized");
        TREASURY = _newTreasury;
    }

    function setPool(address pool, bool value) external {
        require(msg.sender == TREASURY, "Not authorized");
        if (pool == uniswapV2Pair) revert CannotRemoveDefaultPair();
        pools[pool] = value;
    }

    function _applyBasisPoints(uint256 amount, uint256 basisPoints) internal pure returns (uint256) {
        return (amount * basisPoints) / 10_000;
    }

    function _swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }
}
