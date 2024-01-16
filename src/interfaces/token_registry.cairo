use ekubo::interfaces::erc20::{IERC20Dispatcher};

#[starknet::interface]
trait ITokenRegistry<ContractState> {
    fn register_token(ref self: ContractState, token: IERC20Dispatcher);
}

