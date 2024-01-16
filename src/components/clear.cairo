use ekubo::interfaces::erc20::{IERC20Dispatcher, IERC20DispatcherTrait};
use starknet::{ContractAddress, get_contract_address, get_caller_address};

// This component is embedded in the Router and Positions contracts
#[starknet::interface]
trait IClear<TContractState> {
    // Clears the contract's balance of the given token to the caller.
    fn clear(self: @TContractState, token: IERC20Dispatcher) -> u256;
    // Clears the contract's balance of the given token to the caller, and reverts if it's less than the given minimum amount
    fn clear_minimum(self: @TContractState, token: IERC20Dispatcher, minimum: u256) -> u256;
    // Clears the contract's balance of the given token to the given recipient, and reverts if it's less than the given minimum amount
    fn clear_minimum_to_recipient(
        self: @TContractState, token: IERC20Dispatcher, minimum: u256, recipient: ContractAddress
    ) -> u256;
}
