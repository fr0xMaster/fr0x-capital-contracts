// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
/*

pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IUniswapV2Factory} from "@uniswap-core/contracts/interfaces/IUniswapV2Factory.sol";
import {IUniswapV2Router02} from "@uniswap-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract Fr0x is ERC20, Ownable {
    uint256 public MAX_WALLET;
    address public PAIR;
    IUniswapV2Router02 immutable ROUTER = IUniswapV2Router02(0xF491e7B69E4244ad4002BC14e878a34207E38c29);
    uint256 SUPPLY = 100_000_000 * 10 ** 18;
    uint256 TOTAL_FEE = 5;
    bool private _isSwapping;
    address public MARKETING_DEV;
    address public TREASURY;
    uint256 public MARKETING_DEV_FEE;
    uint256 public TREASURY_FEE;
    address immutable WFTM = 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83;

    mapping(address => bool) public pools;
    mapping(address => bool) internal _exemptFromLimits;
    mapping(address => bool) internal _exemptFromFees;

    constructor(address _MARKETING_DEV, address _TREASURY) ERC20("fr0xCapital", "fr0x") Ownable(msg.sender) {
        _mint(msg.sender, SUPPLY);
        MAX_WALLET = (SUPPLY * 2) / 100; //2%
        MARKETING_DEV = _MARKETING_DEV;
        TREASURY = _TREASURY;
        PAIR = IUniswapV2Factory(ROUTER.factory()).createPair(address(this), ROUTER.WETH());
        _approve(address(this), address(ROUTER), SUPPLY);
        IERC20(PAIR).approve(address(ROUTER), type(uint256).max);
        pools[address(PAIR)] = true;
        _exemptFromLimits[address(PAIR)] = true;
    }

    receive() external payable {}

    function _transfer(address from, address to, uint256 amount) internal override {
        _checkWalletLimit(to, amount);
        uint256 finalAmount = _chargeFees(from, to, amount);
        _handleFeeSwap(from, to);
        super._transfer(from, to, finalAmount);
    }

    function _checkWalletLimit(address _to, uint256 amount) internal view {
        if (_to != owner() && _to != address(this) && _to != address(0) && _to != PAIR) {
            require((balanceOf(_to) + amount) <= MAX_WALLET, "Can't hold more than max allet");
        }
    }

    function _chargeFees(address from, address to, uint256 amount) internal returns (uint256) {
        if (_isSwapping) {
            return amount;
        } else {
            uint256 fee = (amount * TOTAL_FEE) / 100;
            super._transfer(from, address(this), fee);
            return amount - fee;
        }
    }

    /// @dev swaps and distributes accumulated fees
    function _handleFeeSwap(address from, address to) internal {
        // non-exempt sellers trigger fee swaps
        if (!_isSwapping && !pools[from] && pools[to] && !_exemptFromFees[from]) {
            _isSwapping = true;
            //_swapAndDistributeFees();
            _isSwapping = false;
        }
    }
}
 */

/*
contract OTSeaERC20 is Ownable, ERC20 {



    function _transfer(address from, address to, uint256 amount) internal override {
        if (PAIR == address(0)) {
            require(
                from == address(this) || from == address(0) || from == owner() || to == owner(),
                "Not started"
            );
            super._transfer(from, to, amount);
            return;
        }

        if (
            from == PAIR && to != address(this) && to != owner() && to != address(router)
        ) {
            require(super.balanceOf(to) + amount <= maxWallet, "max wallet");
        }

        uint256 swapAmount = balanceOf(address(this));

        if (swapAmount > swapAt) {
            swapAmount = swapAt;
        }

        if (swapAt > 0 && swapAmount == swapAt && !inSwap && from != PAIR) {
            inSwap = true;

            swapTokensForEth(swapAmount);

            uint256 balance = address(this).balance;

            if (balance > 0) {
                withdraw(balance);
            }

            inSwap = false;
        }

        uint256 fee;

        if (block.number <= openTradingBlock + 4 && from == PAIR) {
            require(!isContract(to));
            fee = snipeFee;
        } else if (totalFee > 0) {
            fee = totalFee;
        }

        if (fee > 0 && from != address(this) && from != owner() && from != address(router)) {
            uint256 feeTokens = (amount * fee) / 100;
            amount -= feeTokens;

            super._transfer(from, address(this), feeTokens);
        }
        super._transfer(from, to, amount);

    }

    function swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
        _approve(address(this), address(router), tokenAmount);

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function sendFunds(address user, uint256 value) private {
        if (value > 0) {
            (bool success, ) = user.call{value: value}("");
            success;
        }
    }

    function withdraw(uint256 amount) private {
        uint256 toDividends = amount / 5;
        uint256 toOp1 = amount / 10;
        uint256 toOp2 = amount / 10;
        uint256 toMarketing = amount - toDividends - toOp1 - toOp2;

        sendFunds(opWallet1, toOp1);
        sendFunds(opWallet2, toOp2);
        sendFunds(marketingWallet, toMarketing);
    }

 

    function setMarketingWallet(address payable _marketingWallet) external {
        require(msg.sender == marketingWallet, "Not authorized");
        marketingWallet = _marketingWallet;
    }

    function setOpWallet1(address payable _opWallet1) external {
        require(msg.sender == opWallet1, "Not authorized");
        opWallet1 = _opWallet1;
    }

    function setOpWallet2(address payable _opWallet2) external {
        require(msg.sender == opWallet2, "Not authorized");
        opWallet2 = _opWallet2;
    }
}
 */

/*

contract ConkInu is ERC20, Ownable {
    using SafeERC20 for IERC20;
    using Address for address payable;

    bool public inSwap;
    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    mapping(address => bool) public isFeeExempt;
    mapping(address => bool) public canAddLiquidityBeforeLaunch;

    uint256 public maxWallet;
    uint256 private marketingFee;
    uint256 private totalFee;
    uint256 public feeDenominator = 10000;

    uint256 public totalFeeBuy = 300;
    uint256 public totalFeeSell = 500;

    // Fees receivers
    address payable private marketingWallet = payable(0x7D8e6591B128FC284D1245B7F61f8307d96844B2);

    IROUTER02 private immutable swapRouter = IROUTER02(0xF491e7B69E4244ad4002BC14e878a34207E38c29);
    IWFTM private immutable WFTM = IWFTM(0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83);
    address private constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address private constant ZERO = 0x0000000000000000000000000000000000000000;
    
    address public pair;

    constructor() ERC20("ConkInu", "CONKI"){
        uint256 _totalSupply = 1_000_000_000_000 * 1e18;
        maxWallet = (_totalSupply * 5) / 100; //5%

        canAddLiquidityBeforeLaunch[_msgSender()] = true;
        canAddLiquidityBeforeLaunch[address(this)] = true;
        isFeeExempt[msg.sender] = true;
        isFeeExempt[address(this)] = true;
        isFeeExempt[marketingWallet] = true;

        _mint(_msgSender(), _totalSupply);
    }

    receive() external payable {}

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        return _conkInuTransfer(_msgSender(), to, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(sender, spender, amount);
        return _conkInuTransfer(sender, recipient, amount);
    }

    function _conkInuTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        if (inSwap) {
            _transfer(sender, recipient, amount);
            return true;
        }
        checkWalletLimit(recipient, amount);

        // Set Fees
        if (sender == pair) {
            buyFees();
        }
        if (recipient == pair) {
            sellFees();
        }
        if (shouldSwapBack()) {
            swapBack();
        }
        uint256 amountReceived = shouldTakeFee(sender, recipient) ? takeFee(sender, amount) : amount;
        _transfer(sender, recipient, amountReceived);

        return true;
    }

    // Internal Functions
    function shouldSwapBack() internal view returns (bool) {
        return !inSwap && balanceOf(address(this)) > 0 && _msgSender() != pair;
    }

    function swapBack() internal swapping {
        uint256 taxAmount = balanceOf(address(this));
        _approve(address(this), address(swapRouter), taxAmount);

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = address(WFTM);

        swapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(taxAmount, 0, path, address(this), block.timestamp);

        uint256 amountETH = address(this).balance;
        uint256 amountETHMarketing = (amountETH * marketingFee) / totalFee;

        marketingWallet.sendValue(amountETHMarketing);
    }

    function buyFees() internal {
        marketingFee = totalFeeBuy;
        totalFee = marketingFee;
    }

    function sellFees() internal {
        marketingFee = totalFeeSell;
        totalFee = marketingFee;
    }

    function shouldTakeFee(address sender, address recipient) internal view returns (bool) {
        return !isFeeExempt[sender] && !isFeeExempt[recipient];
    }

    function takeFee(address sender, uint256 amount) internal returns (uint256) {
        uint256 feeAmount = (amount * totalFee) / feeDenominator;
        _transfer(sender, address(this), feeAmount);
        return amount - feeAmount;
    }

    function checkWalletLimit(address recipient, uint256 amount) internal view {
        if (recipient != owner() && recipient != address(this) && recipient != address(DEAD) && recipient != pair) {
            uint256 heldTokens = balanceOf(recipient);
            require((heldTokens + amount) <= maxWallet, "You are buying more than what you can have in a single wallet.");
        }
    }

    // Stuck Balances Functions
    function rescueToken(address tokenAddress) external onlyOwner {
        IERC20(tokenAddress).safeTransfer(msg.sender, IERC20(tokenAddress).balanceOf(address(this)));
    }

    function clearStuckBalance() external onlyOwner {
        uint256 amountETH = address(this).balance;
        payable(_msgSender()).sendValue(amountETH);
    }
    ///////////////////////////

    function getCirculatingSupply() public view returns (uint256) {
        return totalSupply() - balanceOf(DEAD) - balanceOf(ZERO);
    }

    function initializePair() external onlyOwner {
        pair = IUniswapV2Factory(swapRouter.factory()).createPair(address(this), address(WFTM));
    }

    function setFeeReceivers(address _marketingWallet) external onlyOwner {
        marketingWallet = payable(_marketingWallet);
    }

    function setMaxWallet(uint256 amount) external onlyOwner {
        require(amount >= totalSupply() / 100);
        maxWallet = amount;
    }

    function setIsFeeExempt(address holder, bool exempt) external onlyOwner {
        isFeeExempt[holder] = exempt;
    }

}
 */
