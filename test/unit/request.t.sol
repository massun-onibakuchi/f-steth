// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../shared/request.t.sol";

contract RequestUnitTest is RequestTest {
    function setUp() public override {
        super.setUp();
    }

    function test_WhenMoreThanDesiredBuffer() public whenEnoughBufferBalance {
        uint256 requestWithdraw = _requestWithdrawal();
        assertEq(requestWithdraw, 0);
    }

    function test_WhenLessThanDesiredBuffer() public whenNotEnoughBufferBalance {
        uint256 balance = stETH.balanceOf(address(fstETH));
        uint256 requestWithdraw = _requestWithdrawal();
        uint256 delta = balance - stETH.balanceOf(address(fstETH));
        // assert
        assertGt(requestWithdraw, 0, "shoud not be greater than 0");
        assertEq(requestWithdraw, delta, "shoud be equal to delta");
        uint256[] memory requestIds = this.getWithdrawalRequests(address(fstETH));
        for (uint256 i = 0; i < requestIds.length; i++) {
            assertEq(fstETH.requestIdsIssuedBySelf(requestIds[i]), true, "request id should be issued by self");
        }
    }

    /// @dev Helper function to get withdrawal requests
    function getWithdrawalRequests(address _owner) external view returns (uint256[] memory requestsIds) {
        (bool s, bytes memory returndata) =
            address(unstEthNft).staticcall(abi.encodeWithSignature("getWithdrawalRequests(address)", _owner));
        require(s, string(returndata));
        return abi.decode(returndata, (uint256[]));
    }
}
