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
    bool public transferDelayEnabled = true;
    bool public limitsEnabled = true;

    uint256 public SELL_FEE = 500; // 5%
    uint256 public BUY_FEE = 500; // 5%

    address public TREASURY;
    address public MARKETING_DEV;
    bool private _isSwapping;

    mapping(address => bool) public pools;
    mapping(address => bool) public exemptFromLimitsAndFee;

    // EVENTS
    event FeeExemption(address indexed account, bool isExempt);
    event PoolUpdate(address indexed pair, bool indexed value);

    // ERRORS
    error NotEnoughBalanceToOpenTrading();

    error CannotRemoveDefaultPair();
    error MaximumFee();
    error MinimumLimit();
    error MinimumSwapThreshold();
    error MaximumSwapThreshold();
    error TradingDisabled();
    error AlreadyInitialized();
    error BlockTransferLimit();
    error TradeLimitExceeded();
    error WalletLimitExceeded();

    constructor(address _treasury, address _marketingDev) ERC20("fr0xCapital", "fr0x") {
        uniswapV2Router = IUniswapV2Router02(0xF491e7B69E4244ad4002BC14e878a34207E38c29); //SpookySwap Router
        tradeLimit = _applyBasisPoints(TOTAL_SUPPLY, 200); // 2%
        walletLimit = _applyBasisPoints(TOTAL_SUPPLY, 200); // 2%
        feeSwapThreshold = _applyBasisPoints(TOTAL_SUPPLY, 5); // 0.05%

        TREASURY = _treasury;
        MARKETING_DEV = _marketingDev;

        exemptFromLimitsAndFee[address(uniswapV2Router)] = true;
        exemptFromLimitsAndFee[owner()] = true;
        exemptFromLimitsAndFee[TREASURY] = true;
        exemptFromLimitsAndFee[MARKETING_DEV] = true;
        exemptFromLimitsAndFee[address(this)] = true;
        _mint(address(this), TOTAL_SUPPLY);
    }

    function openTrading(address _lpOwner) external payable onlyOwner {
        if (tradingEnabled) revert AlreadyInitialized();
        require(msg.value == 1000 ether, "Need 1000 FTM to Open Trading");
        _approve(address(this), address(uniswapV2Router), TOTAL_SUPPLY);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint256).max);
        pools[address(uniswapV2Pair)] = true;
        exemptFromLimitsAndFee[address(uniswapV2Pair)] = true;
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(
            address(this), balanceOf(address(this)), 0, 0, _lpOwner, block.timestamp
        );
        tradingEnabled = true;
    }

    receive() external payable {}

    function _applyBasisPoints(uint256 amount, uint256 basisPoints) internal pure returns (uint256) {
        return (amount * basisPoints) / 10_000;
    }

    /*
    // --------------
    // TRANSFER

    function _transfer(address from, address to, uint256 amount) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        _handleLimits(from, to, amount);
        uint256 finalAmount = _chargeFees(from, to, amount);
        _handleFeeSwap(from, to);

        super._transfer(from, to, finalAmount);
    }

    // --------------
    // LIMITS

    function _handleLimits(address from, address to, uint256 amount) internal {
        if (!limitsEnabled || _isSwapping || from == owner() || to == owner()) {
            return;
        }

        if (!tradingEnabled && !_exemptFromLimits[from] && !_exemptFromLimits[to]) {
            revert TradingDisabled();
        }

        _applyLimits(from, to, amount);
    }

    

    /// @dev Apply trade and balance limits
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

    // --------------
    // FEES

    function _chargeFees(address from, address to, uint256 amount) internal returns (uint256) {
        if (_isSwapping || _exemptFromFees[from] || _exemptFromFees[to]) {
            return amount;
        }

        uint256 fees = 0;
        if (pools[to] && sellFee > 0) {
            fees = _applyBasisPoints(amount, sellFee);
        } else if (pools[from] && buyFee > 0) {
            fees = _applyBasisPoints(amount, buyFee);
        }

        if (fees > 0) {
            super._transfer(from, address(this), fees);
        }

        return amount - fees;
    }

    /// @dev swaps and distributes accumulated fees
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

        (bool sent,) = _teamWallet.call{value: address(this).balance}("");
        require(sent, "send failed");
    }

    // --------------
    // ADMIN

    function removeLimits() external onlyOwner {
        limitsEnabled = false;
    }

    function disableTransferDelay() external onlyOwner {
        transferDelayEnabled = false;
    }

    /// @notice Set swap size limit to `amount` tokens (in token units)
    function setTradeLimit(uint256 amount) external onlyOwner {
        // minimim 0.1% of supply
        amount *= 1e18;
        if (amount < _applyBasisPoints(TOTAL_SUPPLY, 10)) revert MinimumLimit();
        tradeLimit = amount;
    }

    /// @notice Set wallet balance limit to `amount` tokens (in token units)
    function setWalletLimit(uint256 amount) external onlyOwner {
        // minimim 0.1% of supply
        amount *= 1e18;
        if (amount < _applyBasisPoints(TOTAL_SUPPLY, 10)) revert MinimumLimit();
        walletLimit = amount;
    }

    function setExemptFromFees(address addr, bool exempt) external onlyOwner {
        _exemptFromFees[addr] = exempt;
        emit FeeExemption(addr, exempt);
    }

    function setExemptFromLimits(address addr, bool exempt) external onlyOwner {
        _exemptFromLimits[addr] = exempt;
    }

    /// Set buy fee in basis points
    function setBuyFee(uint256 fee) external onlyOwner {
        if (fee > 500) revert MaximumFee(); // 5%
        buyFee = fee;
    }

    /// Set sell fee in basis points
    function setSellFee(uint256 fee) external onlyOwner {
        if (fee > 500) revert MaximumFee(); // 5%
        sellFee = fee;
    }

    function setPool(address pool, bool value) external onlyOwner {
        if (pool == uniswapV2Pair) revert CannotRemoveDefaultPair();
        _setPool(pool, value);
    }

    function _setPool(address pool, bool value) private {
        pools[pool] = value;
        emit PoolUpdate(pool, value);
    }

    /// @notice Set fee swap threshold to `basisPoints` as a fraction of total supply
    /// Set to 10000 to disable fee swaps
    function setFeeSwapThreshold(uint256 basisPoints) external onlyOwner {
        if (basisPoints < 1) revert MinimumSwapThreshold();
        if (basisPoints > 10_000) revert MaximumSwapThreshold();
        feeSwapThreshold = _applyBasisPoints(TOTAL_SUPPLY, basisPoints);
    }

    function setTeamWallet(address addr) external onlyOwner {
        _teamWallet = payable(addr);
    }

    // --------------
    // HELPERS


    function _swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }
    */
}
