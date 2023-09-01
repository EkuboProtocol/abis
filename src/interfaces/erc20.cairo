use starknet::{ContractAddress};

// A simplified interface for a fungible token standard. 
#[starknet::interface]
trait IERC20<TStorage> {
    // Transfers the amount to the recipient from the caller
    // Note there is no bool return value in this interface, because we do not use it. It is assumed
    // the transfer will revert if the caller has insufficient balance.
    fn transfer(ref self: TStorage, recipient: ContractAddress, amount: u256) -> bool;
    // Returns the current balance of the account.
    fn balanceOf(self: @TStorage, account: ContractAddress) -> u256;
}
