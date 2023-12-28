// SPDX-License-Identifier: MIT
/* solhint-disable var-name-mixedcase */
/* solhint-disable func-name-mixedcase */
/* solhint-disable  private-vars-leading-underscore */
pragma solidity ^0.8.20;

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

contract Fr0x is ERC20, Ownable {
    uint256 public constant TOTAL_SUPPLY = 10_000_000_000 * 1e18;

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public uniswapV2Pair;
    uint256 public tradeLimit;
    uint256 public walletLimit;
    uint256 public feeSwapThreshold;
    bool public tradingEnabled;
    uint256 public limitsBefore;

    uint256 public SELL_FEE = 500; // 5%
    uint256 public BUY_FEE = 500; // 5%

    address public TREASURY;
    address public MARKETING_DEV;
    bool private _isSwapping;

    mapping(address => bool) public pools;
    mapping(address => bool) internal _exemptFromLimits;
    mapping(address => bool) internal _exemptFromFees;

    error CannotRemoveDefaultPair();
    error TradingDisabled();
    error AlreadyInitialized();
    error TradeLimitExceeded();
    error WalletLimitExceeded();

    constructor(address _treasury, address _marketingDev) ERC20("fr0xCapital", "fr0x") {
        uniswapV2Router = IUniswapV2Router02(0xF491e7B69E4244ad4002BC14e878a34207E38c29); //SpookySwap Router
        tradeLimit = _applyBasisPoints(TOTAL_SUPPLY, 250); // 2.5%
        walletLimit = _applyBasisPoints(TOTAL_SUPPLY, 250); // 2.5%
        feeSwapThreshold = _applyBasisPoints(TOTAL_SUPPLY, 5); // 0.05%

        limitsBefore = block.timestamp + 6 hours;

        TREASURY = _treasury;
        MARKETING_DEV = _marketingDev;

        _exemptFromLimits[address(uniswapV2Router)] = true;
        _exemptFromLimits[owner()] = true;
        _exemptFromLimits[address(this)] = true;
        _exemptFromFees[owner()] = true;
        _exemptFromFees[address(this)] = true;

        _mint(address(this), TOTAL_SUPPLY);
    }

    function openTrading(address _lpOwner) external payable onlyOwner {
        if (tradingEnabled) revert AlreadyInitialized();
        require(msg.value == 1000 ether, "Need 1000 FTM to Open Trading");
        _approve(address(this), address(uniswapV2Router), TOTAL_SUPPLY);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint256).max);
        pools[address(uniswapV2Pair)] = true;
        _exemptFromLimits[address(uniswapV2Pair)] = true;
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(
            address(this), balanceOf(address(this)), 0, 0, _lpOwner, block.timestamp
        );
        tradingEnabled = true;
    }

    receive() external payable {}

    function _transfer(address from, address to, uint256 amount) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        if (block.timestamp < limitsBefore) _handleLimits(from, to, amount);
        uint256 finalAmount = _chargeFees(from, to, amount);
        _handleFeeSwap(from, to);

        super._transfer(from, to, finalAmount);
    }

    function _handleLimits(address from, address to, uint256 amount) internal view {
        if (_isSwapping || from == owner() || to == owner()) {
            return;
        }

        if (!tradingEnabled && !_exemptFromLimits[from] && !_exemptFromLimits[to]) {
            revert TradingDisabled();
        }

        _applyLimits(from, to, amount);
    }

    function _applyLimits(address from, address to, uint256 amount) internal view {
        // buy
        if (pools[from] && !_exemptFromLimits[to]) {
            if (amount > tradeLimit) revert TradeLimitExceeded();
            if (amount + balanceOf(to) > walletLimit) revert WalletLimitExceeded();
        }
        // sell
        else if (pools[to] && !_exemptFromLimits[from]) {
            if (amount > tradeLimit) revert TradeLimitExceeded();
        }
        // transfer
        else if (!_exemptFromLimits[to]) {
            if (amount + balanceOf(to) > walletLimit) revert WalletLimitExceeded();
        }
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
        uint256 feesForMarketingDev = address(this).balance - feesForTreasury; //25%
        (bool sentToTreasury,) = TREASURY.call{value: feesForTreasury}("");
        require(sentToTreasury, "sent to treasury failed");
        (bool sentToMarketingDev,) = MARKETING_DEV.call{value: feesForMarketingDev}("");
        require(sentToMarketingDev, "sent to Marketing/dev failed");
    }

    function setMarketingWallet(address _newMarketingDev) external {
        require(msg.sender == MARKETING_DEV, "Not authorized");
        MARKETING_DEV = _newMarketingDev;
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
