// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

interface IWithdrawalQueueERC721 {
    struct WithdrawalRequestStatus {
        uint256 amountOfStETH;
        uint256 amountOfShares;
        address owner;
        uint256 timestamp;
        bool isFinalized;
        bool isClaimed;
    }

    function requestWithdrawals(
        uint256[] calldata _amounts,
        address _owner
    ) external returns (uint256[] memory requestIds);

    function claimWithdrawals(uint256[] calldata requestIds, uint256[] calldata hints) external returns (uint256);

    function getWithdrawalStatus(
        uint256[] calldata _requestIds
    ) external view returns (WithdrawalRequestStatus[] memory statuses);
}
