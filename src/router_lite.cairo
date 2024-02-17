use ekubo::types::delta::{Delta};
use ekubo::types::i129::{i129};
use ekubo::types::keys::{PoolKey};
use starknet::{ContractAddress};

#[derive(Serde, Copy, Drop)]
pub struct RouteNode {
    pub pool_key: PoolKey,
    pub sqrt_ratio_limit: u256,
    pub skip_ahead: u128,
}

#[derive(Serde, Copy, Drop)]
pub struct TokenAmount {
    pub token: ContractAddress,
    pub amount: i129,
}

#[derive(Serde, Drop)]
pub struct Swap {
    pub route: Array<RouteNode>,
    pub token_amount: TokenAmount,
}

#[starknet::interface]
pub trait IRouterLite<TContractState> {
    // Does a single swap against a single node using tokens held by this contract, and receives the output to this contract
    fn swap(ref self: TContractState, node: RouteNode, token_amount: TokenAmount) -> Delta;

    // Does a multihop swap, where the output/input of each hop is passed as input/output of the next swap
    // Note to do exact output swaps, the route must be given in reverse
    fn multihop_swap(
        ref self: TContractState, route: Array<RouteNode>, token_amount: TokenAmount
    ) -> Array<Delta>;

    // Does multiple multihop swaps
    fn multi_multihop_swap(ref self: TContractState, swaps: Array<Swap>) -> Array<Array<Delta>>;
}

#[starknet::contract]
pub mod RouterLite {
    use core::array::{Array, ArrayTrait, SpanTrait};
    use core::cmp::{min, max};
    use core::integer::{u256_sqrt};
    use core::num::traits::{Zero};
    use core::option::{OptionTrait};
    use core::result::{ResultTrait};
    use core::traits::{Into};
    use ekubo::components::clear::{ClearImpl};
    use ekubo::components::shared_locker::{
        consume_callback_data, handle_delta, call_core_with_callback
    };
    use ekubo::interfaces::core::{ICoreDispatcher, ICoreDispatcherTrait, ILocker, SwapParameters};
    use ekubo::interfaces::erc20::{IERC20Dispatcher, IERC20DispatcherTrait};
    use ekubo::types::i129::{i129, i129Trait};
    use starknet::syscalls::{call_contract_syscall};

    use starknet::{get_caller_address, get_contract_address};

    use super::{ContractAddress, PoolKey, Delta, IRouterLite, RouteNode, TokenAmount, Swap};

    #[abi(embed_v0)]
    impl Clear = ekubo::components::clear::ClearImpl<ContractState>;

    #[storage]
    struct Storage {
        core: ICoreDispatcher,
    }

    #[constructor]
    fn constructor(ref self: ContractState, core: ICoreDispatcher) {
        self.core.write(core);
    }

    #[abi(embed_v0)]
    impl LockerImpl of ILocker<ContractState> {
        fn locked(ref self: ContractState, id: u32, data: Span<felt252>) -> Span<felt252> {
            let core = self.core.read();

            let mut swaps = consume_callback_data::<Array<Swap>>(core, data);
            let mut outputs: Array<Array<Delta>> = ArrayTrait::new();

            loop {
                match swaps.pop_front() {
                    Option::Some(swap) => {
                        let mut route = swap.route;
                        let mut token_amount = swap.token_amount;

                        let mut deltas: Array<Delta> = ArrayTrait::new();
                        // we track this to know how much to pay in the case of exact input and how much to pull in the case of exact output
                        let mut first_swap_amount: Option<TokenAmount> = Option::None;

                        loop {
                            match route.pop_front() {
                                Option::Some(node) => {
                                    let is_token1 = token_amount.token == node.pool_key.token1;

                                    let delta = core
                                        .swap(
                                            node.pool_key,
                                            SwapParameters {
                                                amount: token_amount.amount,
                                                is_token1: is_token1,
                                                sqrt_ratio_limit: node.sqrt_ratio_limit,
                                                skip_ahead: node.skip_ahead,
                                            }
                                        );

                                    deltas.append(delta);

                                    if first_swap_amount.is_none() {
                                        first_swap_amount =
                                            if is_token1 {
                                                Option::Some(
                                                    TokenAmount {
                                                        token: node.pool_key.token1,
                                                        amount: delta.amount1
                                                    }
                                                )
                                            } else {
                                                Option::Some(
                                                    TokenAmount {
                                                        token: node.pool_key.token0,
                                                        amount: delta.amount0
                                                    }
                                                )
                                            }
                                    }

                                    token_amount =
                                        if (is_token1) {
                                            TokenAmount {
                                                amount: -delta.amount0, token: node.pool_key.token0
                                            }
                                        } else {
                                            TokenAmount {
                                                amount: -delta.amount1, token: node.pool_key.token1
                                            }
                                        };
                                },
                                Option::None => { break (); }
                            };
                        };

                        let recipient = get_contract_address();

                        outputs.append(deltas);

                        let first = first_swap_amount.unwrap();
                        handle_delta(core, token_amount.token, -token_amount.amount, recipient);
                        handle_delta(core, first.token, first.amount, recipient);
                    },
                    Option::None => { break (); }
                };
            };

            let mut serialized: Array<felt252> = array![];

            Serde::serialize(@outputs, ref serialized);

            serialized.span()
        }
    }


    #[abi(embed_v0)]
    impl RouterLiteImpl of IRouterLite<ContractState> {
        fn swap(ref self: ContractState, node: RouteNode, token_amount: TokenAmount) -> Delta {
            let mut deltas: Array<Delta> = self.multihop_swap(array![node], token_amount);
            deltas.pop_front().unwrap()
        }

        #[inline(always)]
        fn multihop_swap(
            ref self: ContractState, route: Array<RouteNode>, token_amount: TokenAmount
        ) -> Array<Delta> {
            let mut result = self.multi_multihop_swap(array![Swap { route, token_amount }]);

            result.pop_front().unwrap()
        }

        #[inline(always)]
        fn multi_multihop_swap(ref self: ContractState, swaps: Array<Swap>) -> Array<Array<Delta>> {
            call_core_with_callback(self.core.read(), @swaps)
        }
    }
}
