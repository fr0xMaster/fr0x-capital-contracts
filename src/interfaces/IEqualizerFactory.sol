// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

interface IEqualizerFactory {
    function MAX_FEE() external view returns (uint256);
    function MAX_FEE_NEW() external view returns (uint256);
    function acceptFeeManager() external;
    function acceptPauser() external;
    function allPairs(uint256) external view returns (address);
    function allPairsLength() external view returns (uint256);
    function createPair(address tokenA, address tokenB, bool stable) external returns (address pair);
    function feeManager() external view returns (address);
    function feesOverrides(address) external view returns (uint256);
    function getFee(bool _stable) external view returns (uint256);
    function getInitializable() external view returns (address, address, bool);
    function getPair(address, address, bool) external view returns (address);
    function getRealFee(address _pair) external view returns (uint256);
    function hotload() external;
    function initialize() external;
    function isPair(address) external view returns (bool);
    function isPaused() external view returns (bool);
    function pairCodeHash() external pure returns (bytes32);
    function pauser() external view returns (address);
    function pendingFeeManager() external view returns (address);
    function pendingPauser() external view returns (address);
    function setFee(bool _stable, uint256 _fee) external;
    function setFeeManager(address _feeManager) external;
    function setFeesOverrides(address _pair, uint256 _fee) external;
    function setPause(bool _state) external;
    function setPauser(address _pauser) external;
    function stableFee() external view returns (uint256);
    function volatileFee() external view returns (uint256);
}
