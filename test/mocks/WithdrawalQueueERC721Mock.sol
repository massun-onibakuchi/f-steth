// SPDX-FileCopyrightText: 2021 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.10;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IWithdrawalQueueERC721} from "src/interfaces/IWithdrawalQueueERC721.sol";

interface Vm {
    function deal(address, uint256) external;
}

contract WithdrawalQueueERC721Mock is IWithdrawalQueueERC721, ERC721("UnstETH", "UNSTETH") {
    uint256 totalSupply;
    IERC20 public constant stETH = IERC20(0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84);
    Vm private constant vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));

    mapping(uint256 => WithdrawalRequestStatus) public requests;

    function requestWithdrawals(uint256[] calldata _amounts, address _owner)
        external
        override
        returns (uint256[] memory requestIds)
    {
        requestIds = new uint256[](_amounts.length);
        for (uint256 i = 0; i < _amounts.length; i++) {
            totalSupply += 1;
            requestIds[i] = totalSupply;
            stETH.transferFrom(msg.sender, address(this), _amounts[i]);
            _mint(_owner, totalSupply);
            requests[totalSupply] = WithdrawalRequestStatus({
                amountOfStETH: _amounts[i],
                amountOfShares: 0,
                owner: _owner,
                timestamp: block.timestamp,
                isFinalized: false,
                isClaimed: false
            });
        }
    }

    function claimWithdrawals(uint256[] calldata requestIds, uint256[] calldata /* hints */ )
        external
        override
        returns (uint256 total)
    {
        for (uint256 i = 0; i < requestIds.length; i++) {
            require(!requests[requestIds[i]].isClaimed, "already claimed");
            require(requests[requestIds[i]].isFinalized, "not finalized");
            requests[requestIds[i]].isClaimed = true;
            total += requests[requestIds[i]].amountOfStETH;
            _burn(requestIds[i]);
        }
        vm.deal(address(this), address(this).balance + total);
        payable(msg.sender).transfer(total);
    }

    function getWithdrawalStatus(uint256[] calldata _requestIds)
        external
        view
        override
        returns (WithdrawalRequestStatus[] memory statuses)
    {
        statuses = new WithdrawalRequestStatus[](_requestIds.length);
        for (uint256 i = 0; i < _requestIds.length; i++) {
            statuses[i] = requests[_requestIds[i]];
        }
    }

    function setRequestClaimed(uint256 _requestId) external {
        requests[_requestId].isClaimed = true;
    }

    function setRequestFinalized(uint256 _requestId) external {
        requests[_requestId].isFinalized = true;
    }
}
