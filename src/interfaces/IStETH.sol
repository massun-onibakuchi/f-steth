// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @notice Interface for deployed stETH.
/// @author Taken from https://github.com/lidofinance/lido-dao/blob/cb19ef08af4078758c52d661f4afe54897e866dd/contracts/0.6.12/interfaces/IStETH.sol
interface IStETH is IERC20 {
    // @notice stETH / wstETH
    function getPooledEthByShares(uint256 _sharesAmount) external view returns (uint256);

    function getSharesByPooledEth(uint256 _pooledEthAmount) external view returns (uint256);

    /**
     * @notice Send funds to the pool with optional _referral parameter
     * @dev This function is alternative way to submit funds. Supports optional referral address.
     * @return Amount of StETH shares generated
     */
    function submit(address _referral) external payable returns (uint256);

    /// @dev Returns the amount of buffered ether in stETH contract
    function getBufferedEther() external view returns (uint256);

    function getTotalShares() external view returns (uint256);

    function getTotalPooledEther() external view returns (uint256);
}
