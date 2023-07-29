// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../shared/claim.t.sol";
import {WithdrawalQueueERC721Mock} from "../mocks/WithdrawalQueueERC721Mock.sol";

contract ClaimUnitTest is ClaimTest {
    using Cast for *;

    uint256 withdrawAmount;
    uint256[] requestIds;

    function setUp() public override {
        super.setUp();
        deployCodeTo("WithdrawalQueueERC721Mock.sol", address(unstEthNft));
        vm.allowCheatcodes(address(unstEthNft));
    }

    modifier requestWithdrawals() {
        (withdrawAmount, requestIds) = fstETH.requestWithdrawalUpToBuffer();
        if (requestIds.length == 0) revert("Test setUp: No request isssued");
        _;
    }

    modifier whenRequestIsFinalized() {
        if (requestIds.length == 0) revert("Test setUp: No request Ids");
        for (uint256 i = 0; i < requestIds.length; i++) {
            unstEthNft.asMock().setRequestFinalized(requestIds[i]);
        }
        _;
    }

    function test_RevertWhen_RequestiNotIssuedBySelf() public {
        uint256[] memory ids = new uint256[](1);
        uint256[] memory hints = new uint256[](1);
        ids[0] = 1;
        vm.expectRevert(abi.encodeWithSelector(FriendlyStETH.WithdrawalRequestNotIssuedByThisContract.selector, 1));
        _claimWithdrawals(ids, hints);
    }

    function test_RevertWhen_AlreadyClaimed()
        public
        whenNotEnoughBufferBalance
        requestWithdrawals
        whenRequestIsFinalized
    {
        unstEthNft.asMock().setRequestClaimed(requestIds[0]);
        uint256[] memory ids = new uint256[](1);
        uint256[] memory hints = new uint256[](1);
        ids[0] = requestIds[0];
        vm.expectRevert("already claimed");
        _claimWithdrawals(ids, hints);
    }

    function test_Claim() public whenNotEnoughBufferBalance requestWithdrawals whenRequestIsFinalized {
        uint256 length = requestIds.length;
        uint256[] memory ids = new uint256[](length);
        uint256[] memory hints = new uint256[](length);
        for (uint256 i = 0; i < length; i++) {
            ids[i] = requestIds[i];
            hints[i] = 0;
        }
        uint256 balBefore = WETH.balanceOf(address(fstETH));
        uint256 claimedEth = _claimWithdrawals(ids, hints);
        uint256 balDelta = WETH.balanceOf(address(fstETH)) - balBefore;
        assertEq(claimedEth, balDelta, "Claimed amount should be equal to requested amount");
        assertApproxEqAbs(balDelta, withdrawAmount, 4, "Pending withdrawal amount should be 0");
        assertApproxEqAbs(fstETH.pendingWithdrawalStEthAmount(), 0, 4, "Pending withdrawal amount should be 0");
    }
}

library Cast {
    // this is helpful to cast with type check. Contract(address(<address type>)) this is not good because <address type> can be arbitary. dev can pass any address and can lead to errors.
    function asMock(IWithdrawalQueueERC721 _mock) internal pure returns (WithdrawalQueueERC721Mock mock) {
        assembly {
            mock := _mock
        }
    }
}
