// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {Ownable} from "openzeppelin/access/Ownable.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";

//import {OlympusYieldSplitter} from "./base/YieldSplitter.sol";

interface IOHMIndexWrapper {
    function index() external view returns (uint256 index);
}

// TODO make into 4626 vault factory
contract House is Ownable {
    using SafeTransferLib for ERC20;

    error House_InsufficientFunds();

    struct DepositInfo {
        uint256 nominalAmount; // Total amount of sOhm deposited as principal, 9 decimals.
        uint256 indexedAmount; // Total amount deposited priced in gOhm. 18 decimals.
    }

    ERC20 public gOhm;
    IOHMIndexWrapper public indexWrapper;

    uint256 public minBuyIn; // nominal amount

    uint256 public totalNominalDeposits;

    mapping(address => uint256) public nominalDeposit;

    constructor(
        ERC20 gOhm_,
        IOHMIndexWrapper index_,
        uint256 minNominalBuyIn_
    ) {
        gOhm = gOhm_;
        indexWrapper = index_;
        minBuyIn = minNominalBuyIn_;
    }

    function deposit(uint256 indexedAmount_) external {
        uint256 userBalance = gOhm.balanceOf(msg.sender);

        if (
            userBalance < indexedAmount_ || userBalance < _toIndexed(minBuyIn)
        ) {
            revert House_InsufficientFunds();
        }

        uint256 nominal = _fromIndexed(indexedAmount_);

        nominalDeposit[msg.sender] += nominal;
        totalNominalDeposits += nominal;

        gOhm.safeTransferFrom(msg.sender, address(this), indexedAmount_);
    }

    function withdraw(uint256 indexedAmount_) external {
        if (nominalDeposit[msg.sender] < indexedAmount_)
            revert House_InsufficientFunds();

        uint256 nominal = _fromIndexed(indexedAmount_);

        nominalDeposit[msg.sender] -= nominal;
        totalNominalDeposits -= nominal;

        gOhm.safeTransferFrom(address(this), msg.sender, indexedAmount_);
    }

    function rewardPrizePool(address winner_) external onlyOwner {
        uint256 prizePool = gOhm.balanceOf(address(this)) -
            _toIndexed(totalNominalDeposits);
        gOhm.safeTransfer(winner_, prizePool);
    }

    function getNominalPrizePool() external view returns (uint256) {
        return
            _fromIndexed(gOhm.balanceOf(address(this))) - totalNominalDeposits;
    }

    function _toIndexed(uint256 indexed_) internal view returns (uint256) {
        return (indexed_ * 1e18) / (indexWrapper.index());
    }

    function _fromIndexed(uint256 indexed_) internal view returns (uint256) {
        return (indexed_ * (indexWrapper.index())) / 1e18;
    }
}
