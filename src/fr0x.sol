// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract Fr0x is ERC20, Ownable {
    using SafeERC20 for IERC20;

    address public MARKETING_DEV;
    address public TREASURY;
    uint256 public MAX_WALLET;
    uint256 public MARKETING_DEV_FEE;
    uint256 public TREASURY_FEE;
    uint256 public BUY_FEE = 5;
    uint256 public SELL_FEE = 5;
    bool public inSwap;
    IUniswapV2Router02 private immutable swapRouter = IUniswapV2Router02(0xF491e7B69E4244ad4002BC14e878a34207E38c29);
    address private immutable WFTM = 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83;
    address public pair;

    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    mapping(address => bool) public isFeeExempt;

    constructor(address _MARKETING_DEV, address _TREASURY) ERC20("fr0xCapital", "FR0X") Ownable(msg.sender) {
        MARKETING_DEV = _MARKETING_DEV;
        TREASURY = _TREASURY;
        uint256 supply = 100_000_000_000 * 1e18;
        MAX_WALLET = (supply * 2) / 100; //2%
        isFeeExempt[msg.sender] = true;
        isFeeExempt[address(this)] = true;
        isFeeExempt[MARKETING_DEV] = true;
        isFeeExempt[TREASURY] = true;
        _mint(msg.sender, supply);
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

        swapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            taxAmount, 0, path, address(this), block.timestamp
        );

        uint256 amountETH = address(this).balance;
        uint256 amountETHMarketing = (amountETH * MARKETING_DEV_FEE) / totalFee;

        MARKETING_DEV.sendValue(amountETHMarketing);
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
        if (recipient != owner() && recipient != address(this) && recipient != pair) {
            uint256 heldTokens = balanceOf(recipient);
            require(
                (heldTokens + amount) <= MAX_WALLET, "You are buying more than what you can have in a single wallet."
            );
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

    /**
     * ADMIN FUNCTIONS **
     */
    function initializePair() external onlyOwner {
        pair = IUniswapV2Factory(swapRouter.factory()).createPair(address(this), address(WFTM));
    }

    function setFeeReceivers(address _marketingWallet) external onlyOwner {
        marketingWallet = payable(_marketingWallet);
    }

    function setMAX_WALLET(uint256 amount) external onlyOwner {
        require(amount >= totalSupply() / 100);
        MAX_WALLET = amount;
    }

    function setIsFeeExempt(address holder, bool exempt) external onlyOwner {
        isFeeExempt[holder] = exempt;
    }
}

/*
contract OTSeaERC20 is Ownable, ERC20 {
    uint256 public maxWallet;
    address public uniswapV2Pair;
    IUniswapV2Router02 immutable router =
        IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    uint256 SUPPLY = 100_000_000 * 10 ** 18;
    uint256 snipeFee = 30;
    uint256 totalFee = 5;

    bool private inSwap = false;
    address public marketingWallet;
    address payable public opWallet1;
    address payable public opWallet2;

    uint256 public openTradingBlock;

    mapping(address => uint256) public receiveBlock;

    uint256 public swapAt = SUPPLY / 1000; //0.1%

    constructor(
        address payable _opWallet1,
        address payable _opWallet2,
        address _marketingWallet
    ) payable ERC20("OTSea", "OTSea") {
        _mint(_marketingWallet, (SUPPLY * 100) / 1000);
        _mint(address(this), (SUPPLY * 900) / 1000);
        maxWallet = SUPPLY;
        opWallet1 = _opWallet1;
        opWallet2 = _opWallet2;
        marketingWallet = _marketingWallet;


    }

    receive() external payable {}

    function isContract(address account) private view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

   
    function updateFee(uint256 _totalFee) external onlyOwner {
        require(_totalFee <= 5, "Fee can only be lowered");
        totalFee = _totalFee;
    }

    function updateMaxHoldingPercent(uint256 percent) public onlyOwner {
        require(percent >= 1 && percent <= 100, "invalid percent");
        maxWallet = (SUPPLY * percent) / 100;
    }

    function updateSwapAt(uint256 value) external onlyOwner {
        require(value <= SUPPLY / 50);
        swapAt = value;
    }

 
    function enterTheSea() external onlyOwner {
        address pair = IUniswapV2Factory(router.factory()).createPair(address(this), router.WETH());
        _approve(address(this), address(router), balanceOf(address(this)));
        router.addLiquidityETH{value: address(this).balance}(
            address(this),
            balanceOf(address(this)),
            0,
            0,
            owner(),
            block.timestamp
        );

        uniswapV2Pair = pair;
        openTradingBlock = block.number;
        updateMaxHoldingPercent(1);
    }

    function _transfer(address from, address to, uint256 amount) internal override {
        if (uniswapV2Pair == address(0)) {
            require(
                from == address(this) || from == address(0) || from == owner() || to == owner(),
                "Not started"
            );
            super._transfer(from, to, amount);
            return;
        }

        if (
            from == uniswapV2Pair && to != address(this) && to != owner() && to != address(router)
        ) {
            require(super.balanceOf(to) + amount <= maxWallet, "max wallet");
        }

        uint256 swapAmount = balanceOf(address(this));

        if (swapAmount > swapAt) {
            swapAmount = swapAt;
        }

        if (swapAt > 0 && swapAmount == swapAt && !inSwap && from != uniswapV2Pair) {
            inSwap = true;

            swapTokensForEth(swapAmount);

            uint256 balance = address(this).balance;

            if (balance > 0) {
                withdraw(balance);
            }

            inSwap = false;
        }

        uint256 fee;

        if (block.number <= openTradingBlock + 4 && from == uniswapV2Pair) {
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
