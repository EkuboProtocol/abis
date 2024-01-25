use ekubo::interfaces::erc20::{IERC20Dispatcher};

#[starknet::interface]
pub trait ITokenRegistry<ContractState> {
    fn register_token(ref self: ContractState, token: IERC20Dispatcher);
}

