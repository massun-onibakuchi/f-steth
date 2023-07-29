// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

interface IWithdrawalQueueERC721 {
    /// @param amountOfStETH — the number of stETH tokens transferred to the contract upon request
    /// @param amountOfShares — the number of underlying shares corresponding to transferred stETH tokens. See Lido rebasing chapter to learn about the shares mechanic
    /// @param owner — the owner's address for this request. The owner is also a holder of the unstETH NFT and can transfer the ownership and claim the underlying ether once finalized
    /// @param timestamp — the creation time of the request
    /// @param isFinalized — finalization status of the request; finalized requests are available to claim
    /// @param isClaimed — the claim status of the request. Once claimed, NFT is burned, and the request is not available to claim again
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
