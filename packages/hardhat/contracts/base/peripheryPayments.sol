// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Currency, CurrencyLibrary} from '../v4-core/src/types/Currency.sol';
import {SafeTransferLib} from "./safeTransferLib.sol";


/// @title Periphery Payments
/// @notice Functions to ease deposits and withdrawals of ETH
interface IPeripheryPayments {
    // TODO: figure out if we still need unwrapWETH9 from v3?

    /// @notice Transfers the full amount of a token held by this contract to recipient
    /// @dev The amountMinimum parameter prevents malicious contracts from stealing the token from users
    /// @param currency The contract address of the token which will be transferred to `recipient`
    /// @param amountMinimum The minimum amount of token required for a transfer
    /// @param recipient The destination address of the token
    function sweepToken(Currency currency, uint256 amountMinimum, address recipient) external payable;
}


abstract contract PeripheryPayments is IPeripheryPayments {
    using CurrencyLibrary for Currency;
    using SafeTransferLib for address;
    using SafeTransferLib for ERC20;

    error InsufficientToken();
    error NativeTokenTransferFrom();

    /// @inheritdoc IPeripheryPayments
    function sweepToken(Currency currency, uint256 amountMinimum, address recipient) public payable override {
        uint256 balanceCurrency = currency.balanceOfSelf();
        if (balanceCurrency < amountMinimum) revert InsufficientToken();

        if (balanceCurrency > 0) {
            currency.transfer(recipient, balanceCurrency);
        }
    }

    /// @param currency The currency to pay
    /// @param payer The entity that must pay
    /// @param recipient The entity that will receive payment
    /// @param value The amount to pay
    function pay(Currency currency, address payer, address recipient, uint256 value) internal {
        if (payer == address(this)) {
            // pay with tokens already in the contract (for the exact input multihop case)
            currency.transfer(recipient, value);
        } else {
            if (currency.isNative()) revert NativeTokenTransferFrom();
            // pull payment
            ERC20(Currency.unwrap(currency)).safeTransferFrom(payer, recipient, value);
        }
    }
}