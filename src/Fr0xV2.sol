// SPDX-License-Identifier: MIT
/* solhint-disable var-name-mixedcase */
/* solhint-disable func-name-mixedcase */
/* solhint-disable  private-vars-leading-underscore */
pragma solidity 0.8.20;

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
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {OFT} from "@layer-zero/oapp/contracts/oft/OFT.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {IUniswapV2Factory} from "@uniswap-core/contracts/interfaces/IUniswapV2Factory.sol";
import {IUniswapV2Router02} from "@uniswap-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import {IEqualizerFactory} from "./interfaces/IEqualizerFactory.sol";
import {IEqualizerRouterV3} from "./interfaces/IEqualizerRouterV3.sol";

contract Fr0xV2 is OFT {
    uint256 public constant TOTAL_SUPPLY = 10_000_000_000 * 1e18;

    IUniswapV2Router02 public immutable uniswapV2Router;
    IEqualizerRouterV3 public immutable equalizerRouterV3;

    address public uniswapV2Pair;
    address public equalizerV3Pair;

    address public immutable layerZeroFantomEndpoint = 0xb6319cC6c8c27A8F5dAF0dD3DF91EA35C4720dd7;

    enum FeeSwapMode {
        MANUALLY,
        EQUALIZER,
        SPOOKY
    }

    FeeSwapMode SWAP_MODE;
    uint256 public feeSwapThreshold;
    uint256 public SELL_FEE = 500; // 5%
    uint256 public BUY_FEE = 500; // 5%
    uint256 public TREASURY_SHARE = 7500; // 75%
    address public TREASURY;
    address public DEVELOPMENT;
    address public MIGRATION;

    bool private _isSwapping;

    mapping(address => bool) public pools;
    mapping(address => bool) internal _exemptFromFees;

    //TODO: Need to mint total supply and transfer at migration contract. => DONE
    //TODO: Need to add setter to add pool in pools => DONE
    //TODO: Need to add setter to add contract in _exemptFromFees => DONE
    //TODO: Need to add setter to change Swap Threshold => DONE
    //TODO: Need to add setter to change fees => DONE
    //TODO: Need to add setter to change share of fees (treasury vs dev) => DONE
    //TODO: ADD a state and a setter to know where to make the swap of fees (spooky, equalizer or manually) => DONE

    //TODO: make it compatible for layer zero

    /*
       1 - Deploy Migration Contract with a function who wiat an address for fro0x v2 and a state to tell Migration is ready
            - Migration contract can be trigger via this function if v2 is deployed and hava an address & Migration balance of v2 Token is TOTAL SUPPLY
       2 - Deploy FroxV2 with the address of Migration Contract and transfer TOTAL SUpply to V2
     */

    /*
    constructor(
        string _name, // token name
        string _symbol, // token symbol
        address _lzEndpoint, // LayerZero Endpoint address
        address _owner, // token owner
    ) {
        // your contract logic here
        _mint(_msgSender(), 100 * 10 * decimals()); // mints 100 tokens to the deployer
    }
     */
    constructor(address _treasury, address _development, address _migration)
        OFT("fr0xCapital", "fr0x", layerZeroFantomEndpoint, owner())
    {
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

        _approve(address(this), address(equalizerRouterV3), TOTAL_SUPPLY);
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

        if (SWAP_MODE == FeeSwapMode.MANUALLY) {
            uint256 fr0xForTreasury = _applyBasisPoints(contractBalance, TREASURY_SHARE);
            uint256 fr0xForDevelopment = contractBalance - fr0xForTreasury;
            bool fr0xToTreasury = transfer(TREASURY, fr0xForTreasury);
            require(fr0xToTreasury, "sent to treasury failed");
            bool fr0xToDevelopment = transfer(DEVELOPMENT, fr0xForDevelopment);
            require(fr0xToDevelopment, "sent to development failed");
        } else {
            SWAP_MODE == FeeSwapMode.EQUALIZER
                ? _swapTokensForEthOnEqualizer(contractBalance)
                : _swapTokensForEthOnSpooky(contractBalance);

            uint256 ftmForTreasury = _applyBasisPoints(address(this).balance, TREASURY_SHARE);
            uint256 ftmForDevelopment = address(this).balance - ftmForTreasury;

            (bool ftmToTreasury,) = TREASURY.call{value: ftmForTreasury}("");
            require(ftmToTreasury, "sent to treasury failed");
            (bool ftmToDevelopment,) = DEVELOPMENT.call{value: ftmForDevelopment}("");
            require(ftmToDevelopment, "sent to Marketing/dev failed");
        }
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
        pools[pool] = value;
    }

    function setExemptForFees(address _contract, bool value) external {
        require(msg.sender == TREASURY, "Not authorized");
        _exemptFromFees[_contract] = value;
    }

    function setBuyFee(uint256 _fee) external {
        require(msg.sender == TREASURY, "Not authorized");
        require(_fee <= 500, "Limited to 5%");
        BUY_FEE = _fee;
    }

    function setSellFee(uint256 _fee) external {
        require(msg.sender == TREASURY, "Not authorized");
        require(_fee <= 500, "Limited to 5%");
        SELL_FEE = _fee;
    }

    function setFeeSwapThreshold(uint256 _basisPoints) external {
        require(msg.sender == TREASURY, "Not authorized");
        require(_basisPoints >= 1, "Minimum 1");
        require(_basisPoints <= 10_000, "Maximum 10000");
        feeSwapThreshold = _applyBasisPoints(TOTAL_SUPPLY, _basisPoints);
    }

    function setFeeSwapMode(FeeSwapMode _mode) external {
        require(msg.sender == TREASURY, "Not authorized");
        SWAP_MODE = _mode;
    }

    function setTreasuryShareOfFees(uint256 _share) external {
        require(msg.sender == TREASURY, "Not authorized");
        require(_share <= 10_000, "Maximum 10000");
        TREASURY_SHARE = _share;
    }

    function _applyBasisPoints(uint256 amount, uint256 basisPoints) internal pure returns (uint256) {
        return (amount * basisPoints) / 10_000;
    }

    function _swapTokensForEthOnSpooky(uint256 tokenAmount) private {
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

    function _swapTokensForEthOnEqualizer(uint256 tokenAmount) private {
        IEqualizerRouterV3.Route[] memory routes;
        routes[0] = IEqualizerRouterV3.Route({from: address(this), to: equalizerRouterV3.weth(), stable: false});

        _approve(address(this), address(uniswapV2Router), tokenAmount);
        equalizerRouterV3.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            routes,
            address(this),
            block.timestamp
        );
    }
}
