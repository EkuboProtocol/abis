use core::num::traits::{Zero};
use ekubo::interfaces::erc20::{IERC20Dispatcher, IERC20DispatcherTrait};
use starknet::{ContractAddress, get_contract_address, get_caller_address};

#[starknet::interface]
pub trait IClear<TContractState> {
    // Clears the contract's balance of the given token to the caller.
    fn clear(self: @TContractState, token: IERC20Dispatcher) -> u256;
    // Clears the contract's balance of the given token to the caller, and reverts if it's less than the given minimum amount
    fn clear_minimum(self: @TContractState, token: IERC20Dispatcher, minimum: u256) -> u256;
    // Clears the contract's balance of the given token to the given recipient, and reverts if it's less than the given minimum amount
    fn clear_minimum_to_recipient(
        self: @TContractState, token: IERC20Dispatcher, minimum: u256, recipient: ContractAddress
    ) -> u256;
}

#[starknet::embeddable]
pub impl ClearImpl<TContractState> of IClear<TContractState> {
    fn clear(self: @TContractState, token: IERC20Dispatcher) -> u256 {
        self.clear_minimum_to_recipient(token, 0, get_caller_address())
    }

    fn clear_minimum(self: @TContractState, token: IERC20Dispatcher, minimum: u256) -> u256 {
        self.clear_minimum_to_recipient(token, minimum, get_caller_address())
    }

    fn clear_minimum_to_recipient(
        self: @TContractState, token: IERC20Dispatcher, minimum: u256, recipient: ContractAddress
    ) -> u256 {
        let balance = token.balanceOf(get_contract_address());
        if minimum.is_non_zero() {
            assert(balance >= minimum, 'CLEAR_AT_LEAST_MINIMUM');
        }
        if balance.is_non_zero() {
            token.transfer(recipient, balance);
        }
        balance
    }
}
