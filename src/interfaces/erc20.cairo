use starknet::{ContractAddress};

// A simplified interface for a fungible token standard.
#[starknet::interface]
pub trait IERC20<TContractState> {
    // Transfers the amount to the recipient from the caller
    // Note there is no bool return value in this interface, because we do not use it. It is assumed
    // the transfer will revert if the caller has insufficient balance.
    fn transfer(ref self: TContractState, recipient: ContractAddress, amount: u256) -> bool;
    // Returns the current balance of the account.
    fn balanceOf(self: @TContractState, account: ContractAddress) -> u256;

    // Approves the given address to spend the given amount
    fn approve(ref self: TContractState, spender: ContractAddress, amount: u256) -> bool;

    // Transfers the amount from the `sender` address to the `recipient` address.
    // The caller must be approved for at least the `amount`.
    fn transferFrom(
        ref self: TContractState, sender: ContractAddress, recipient: ContractAddress, amount: u256
    ) -> bool;

    // Returns the current allowance of the given owner to spender
    fn allowance(self: @TContractState, owner: ContractAddress, spender: ContractAddress) -> u256;
}
