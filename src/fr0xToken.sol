// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IUniswapV2Factory} from "@uniswap-core/contracts/interfaces/IUniswapV2Factory.sol";
import {IUniswapV2Router02} from "@uniswap-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract BBSToken is ERC20, Ownable {
    IUniswapV2Router02 private _uniswapV2Router = IUniswapV2Router02(0xF491e7B69E4244ad4002BC14e878a34207E38c29); //Spookyswap Router
    address private _uniswapV2Pair;

    uint256 public maxHoldings;
    uint256 public feeTokenThreshold;
    bool public feesDisabled = false;
    bool public feesDisabledBackup = false;
    bool public startTrading = false; // Have trading disabled initially so fees and settings can all be done correctly, once enabled trading can't be stopped
    bool public liquidityAddMode = false;

    // Dev Fees
    bool private _inSwap;
    uint256 public _devFee = 2;
    uint256 private _tokensForFee;
    address public _feeAddr;

    // Trade Farmer Fees
    uint256 private _tokensForFarm;
    mapping(address => bool) public liquidityPools; // Add all liquidity pools that will support farming slots
    mapping(address => uint256) public farmingLeaderboard; // Keep track of each farmers rewards for dashboard
    address[] public farmingLUT; //Look up table to fetch all farmers in leaderboard
    address[] public farmers = [
        0x000000000000000000000000000000000000dEaD,
        0x000000000000000000000000000000000000dEaD,
        0x000000000000000000000000000000000000dEaD,
        0x000000000000000000000000000000000000dEaD,
        0x000000000000000000000000000000000000dEaD,
        0x000000000000000000000000000000000000dEaD,
        0x000000000000000000000000000000000000dEaD,
        0x000000000000000000000000000000000000dEaD,
        0x000000000000000000000000000000000000dEaD,
        0x000000000000000000000000000000000000dEaD,
        0x000000000000000000000000000000000000dEaD,
        0x000000000000000000000000000000000000dEaD,
        0x000000000000000000000000000000000000dEaD,
        0x000000000000000000000000000000000000dEaD,
        0x000000000000000000000000000000000000dEaD,
        0x000000000000000000000000000000000000dEaD,
        0x000000000000000000000000000000000000dEaD,
        0x000000000000000000000000000000000000dEaD,
        0x000000000000000000000000000000000000dEaD,
        0x000000000000000000000000000000000000dEaD
    ]; // Set first 15 farmers to dead address
    uint256[] farmerWeight = [2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2];
    uint256[] farmerPayout = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
    uint256 public farmerFees = 3;
    uint256 private totalWeights = 40;
    uint256 public minFarmAmt = 1000 * (10 ** 18); // How many traders need to swap to get on farming slot
    uint256 public farmerCount = 0;
    bool public liquidityDeposited = false;

    uint256 public burnedSupply = 0;

    mapping(address => bool) public farmingDenyList;

    mapping(address => bool) private _whitelisted;

    // much like onlyOwner() but used for the feeAddr so that once renounced fees and maxholdings can still be disabled
    modifier onlyFeeAddr() {
        require(_feeAddr == _msgSender(), "Caller is not the _feeAddr address.");
        _;
    }

    constructor(address feeAddr) payable ERC20("BatmanBinSuparman", "BBS") {
        uint256 totalSupply = 100000000000 * (10 ** 18);
        uint256 totalLiquidity = totalSupply * 90 / 100; // 90%

        maxHoldings = totalSupply * 2 / 100; // 2% can be held by a wallet at one time
        feeTokenThreshold = totalSupply * 1 / 1000; // .1% to swap tokens held by contract for dev/marketing fees

        _feeAddr = feeAddr; // Address of wallet earning fees

        // exclution from fees and limits
        _whitelisted[owner()] = true;
        _whitelisted[address(this)] = true;
        _whitelisted[address(0xdead)] = true;

        // mint lp tokens to the contract and remaning to deployer
        _mint(address(this), totalLiquidity);
        _mint(msg.sender, totalSupply.sub(totalLiquidity));
    }

    function createV2LP() external onlyOwner {
        // Allow liquidity addition normally
        liquidityAddMode = true;

        // create pair
        _uniswapV2Pair =
            IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());

        // add lp to pair
        _addLiquidity(balanceOf(address(this)), address(this).balance);

        liquidityAddMode = false;
    }

    // updates the amount of tokens that needs to be reached before fee is swapped
    function updateFeeTokenThreshold(uint256 newThreshold) external onlyFeeAddr {
        require(newThreshold >= totalSupply() * 1 / 100000, "Swap threshold cannot be lower than 0.001% total supply.");
        require(newThreshold <= totalSupply() * 5 / 1000, "Swap threshold cannot be higher than 0.5% total supply.");
        feeTokenThreshold = newThreshold;
    }

    function _transfer(address from, address to, uint256 amount) internal virtual override {
        require(from != address(0), "Transfer from the zero address not allowed.");
        require(to != address(0), "Transfer to the zero address not allowed.");
        require(startTrading || liquidityAddMode, "Trading hasn't started yet! Hold your horses Suparman");

        // no reason to waste gas
        bool isBuy = from == _uniswapV2Pair;
        bool excluded = _whitelisted[from] || _whitelisted[to];
        bool isFarmer = (
            to == farmers[0] || to == farmers[1] || to == farmers[2] || to == farmers[3] || to == farmers[4]
                || to == farmers[5] || to == farmers[6] || to == farmers[7] || to == farmers[8] || to == farmers[9]
                || to == farmers[10] || to == farmers[11] || to == farmers[12] || to == farmers[13] || to == farmers[14]
                || to == farmers[15] || to == farmers[16] || to == farmers[17] || to == farmers[18] || to == farmers[19]
        );

        uint256 finalAmount = amount;
        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        // if pair has not yet been created
        if (_uniswapV2Pair == address(0)) {
            require(excluded, "Please wait for the LP pair to be created.");
            return;
        }

        // max holding check
        if (maxHoldings > 0 && isBuy && to != owner() && to != address(this) && !isFarmer) {
            require(
                super.balanceOf(to) + amount <= maxHoldings,
                "Balance exceeds max holdings amount, consider using a second wallet."
            );
        }

        // take fees if they haven't been perm disabled
        if (!feesDisabled) {
            uint256 contractTokenBalance = balanceOf(address(this));
            bool canSwap = contractTokenBalance >= feeTokenThreshold;
            if (canSwap && !_inSwap && !isBuy && !_whitelisted[from] && !_whitelisted[to]) {
                _inSwap = true;
                swapFee();
                _inSwap = false;
            }

            // check if we should be taking the fee
            bool takeFee = !_inSwap;
            if (excluded || !isBuy && to != _uniswapV2Pair) takeFee = false;

            if (takeFee) {
                _tokensForFee = amount.mul(_devFee).div(100);
                _tokensForFarm = amount.mul(farmerFees).div(100);

                if (_tokensForFee > 0) {
                    super._transfer(from, address(this), _tokensForFee);
                }

                finalAmount -= _tokensForFee;
            }
        }

        // Trade farming transfer code here
        if (startTrading && !feesDisabled) {
            feesDisabled = true;
            // Pay out to trade farmers in cycle
            totalWeights = farmerWeight[0].add(farmerWeight[1]).add(farmerWeight[2]).add(farmerWeight[3]).add(
                farmerWeight[4]
            ).add(farmerWeight[5]).add(farmerWeight[6]).add(farmerWeight[7]).add(farmerWeight[8]).add(farmerWeight[9])
                .add(farmerWeight[10]).add(farmerWeight[11]).add(farmerWeight[12]).add(farmerWeight[13]).add(
                farmerWeight[14]
            ).add(farmerWeight[15]).add(farmerWeight[16]).add(farmerWeight[17]).add(farmerWeight[18]).add(
                farmerWeight[19]
            );

            //Trade To Farm Integration payout farmers and add to leaderboard
            for (uint8 x = 0; x < 20; x++) {
                farmerPayout[x] = _tokensForFarm.div(totalWeights).mul(farmerWeight[x]);
                super._transfer(from, farmers[x], farmerPayout[x]);
                farmingLeaderboard[farmers[x]] += farmerPayout[x];
            }

            finalAmount -= _tokensForFarm;

            //Add recipient to farming slot, one recipient cannot occupy two or morefarming slots
            if (liquidityPools[msg.sender] && amount >= minFarmAmt && !farmingDenyList[to] && !isFarmer) {
                farmers[farmerCount] = to;
                farmerWeight[farmerCount] = (amount / 10 ** 18);
                farmerCount++;
                if (farmerCount > 19) {
                    farmerCount = 0;
                }

                if (!(farmingLeaderboard[to] > 0)) {
                    farmingLUT.push(to);
                }
            }
            feesDisabled = feesDisabledBackup;
        }

        super._transfer(from, to, finalAmount);
    }

    // swaps tokens to eth
    function _swapTokensForEth(uint256 tokenAmount) internal {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _uniswapV2Router.WETH();

        _approve(address(this), address(_uniswapV2Router), tokenAmount);

        _uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount, 0, path, address(this), block.timestamp
        );
    }

    // does what it says
    function _addLiquidity(uint256 tokenAmount, uint256 ethAmount) internal {
        _approve(address(this), address(_uniswapV2Router), tokenAmount);

        _uniswapV2Router.addLiquidityETH{value: ethAmount}(address(this), tokenAmount, 0, 0, _feeAddr, block.timestamp);
    }

    // swaps fee from tokens to eth
    function swapFee() internal {
        uint256 contractBal = balanceOf(address(this));

        if (contractBal == 0 || _tokensForFee == 0) return;
        if (contractBal > feeTokenThreshold) contractBal = feeTokenThreshold;

        _swapTokensForEth(contractBal);

        uint256 ethBalance = address(this).balance;
        _tokensForFee = 0;

        payable(_feeAddr).transfer(ethBalance);
    }

    // perm disable fees
    function disableFees() external onlyFeeAddr {
        feesDisabled = true;
        feesDisabledBackup = true;
        farmerFees = 0;
    }

    // Minimum amount a person has to trade to be added to a farming slot
    function setMinimumFarmingAmount(uint256 newMinimum) external onlyFeeAddr {
        minFarmAmt = newMinimum;
    }

    // If we list in multiple dexes need to be able to add trade farming for other dexes
    function addLiquidityPool(address newLiquidityPool) external onlyFeeAddr {
        liquidityPools[newLiquidityPool] = true;
    }

    // Wallet address that is whitelisted from all fees
    function addToWhitelistFees(address newAddress) external onlyFeeAddr {
        _whitelisted[newAddress] = true;
    }

    // Wallet address that is removed from whitelist from all fees
    function removeFromWhitelistFees(address newAddress) external onlyFeeAddr {
        _whitelisted[newAddress] = false;
    }

    // Only stops a wallet from farming trade to earn fees (example a bot is abusing the system), but the wallet can still trade
    function denyFarmingFees(address newAddress) external onlyFeeAddr {
        farmingDenyList[newAddress] = true;
    }

    //Get number of trade farmers in leaderboard
    function numFarmers() public view returns (uint256) {
        return farmingLUT.length;
    }

    // perm disable max holdings
    function disableHoldingLimit() external onlyFeeAddr {
        maxHoldings = 0;
    }

    // transfers any stuck eth from contract to feeAddr
    function transferStuckETH() external {
        payable(_feeAddr).transfer(address(this).balance);
    }

    // Once trading starts it can't be stopped, so only enable once all settings are correctly done such as LP
    function startTradingBBS() external onlyOwner {
        startTrading = true;
    }

    receive() external payable {}
}
