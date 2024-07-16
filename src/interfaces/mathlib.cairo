use ekubo::types::delta::{Delta};
use ekubo::types::i129::{i129};

// Returns the dispatcher for the math library that is deployed on sepolia and mainnet with the given interface.
pub fn dispatcher() -> IMathLibLibraryDispatcher {
    IMathLibLibraryDispatcher {
        class_hash: 0x030abe5287c07338f1629c0b6925e1fe964804b6d71aadd356b0b345326b7de0_felt252
            .try_into()
            .unwrap()
    }
}

#[starknet::interface]
pub trait IMathLib<TContractState> {
    // Computes the difference in token0 reserves between the two prices given the constant liquidity, optionally rounded up
    fn amount0_delta(
        self: @TContractState,
        sqrt_ratio_a: u256,
        sqrt_ratio_b: u256,
        liquidity: u128,
        round_up: bool
    ) -> u128;
    // Computes the difference in token1 reserves between the two prices given the constant liquidity, optionally rounded up
    fn amount1_delta(
        self: @TContractState,
        sqrt_ratio_a: u256,
        sqrt_ratio_b: u256,
        liquidity: u128,
        round_up: bool
    ) -> u128;
    // Computes the difference in token0 and token1 given a liquidity delta, rounding up for positive and down for negative
    fn liquidity_delta_to_amount_delta(
        self: @TContractState,
        sqrt_ratio: u256,
        liquidity_delta: i129,
        sqrt_ratio_lower: u256,
        sqrt_ratio_upper: u256
    ) -> Delta;
    // Computes the max liquidity that can be received for the given amount of token0 and the lower/upper bounds, assuming the current price is not within the bounds
    fn max_liquidity_for_token0(
        self: @TContractState, sqrt_ratio_lower: u256, sqrt_ratio_upper: u256, amount: u128
    ) -> u128;
    // Computes the max liquidity that can be received for the given amount of token1 and the lower/upper bounds, assuming the current price is not within the bounds
    fn max_liquidity_for_token1(
        self: @TContractState, sqrt_ratio_lower: u256, sqrt_ratio_upper: u256, amount: u128
    ) -> u128;
    // Computes the max liquidity that can be received for the given amount of token0 and token1 and the lower/upper bounds and current price
    fn max_liquidity(
        self: @TContractState,
        sqrt_ratio: u256,
        sqrt_ratio_lower: u256,
        sqrt_ratio_upper: u256,
        amount0: u128,
        amount1: u128
    ) -> u128;

    // Compute the next sqrt ratio that will be reached from a swap given an amount of token0. Can return an Option::None in case of overflow or underflow
    fn next_sqrt_ratio_from_amount0(
        self: @TContractState, sqrt_ratio: u256, liquidity: u128, amount: i129
    ) -> Option<u256>;
    // Compute the next sqrt ratio that will be reached from a swap given an amount of token1. Can return an Option::None in case of overflow or underflow
    fn next_sqrt_ratio_from_amount1(
        self: @TContractState, sqrt_ratio: u256, liquidity: u128, amount: i129
    ) -> Option<u256>;

    // Converts a tick to the sqrt ratio
    fn tick_to_sqrt_ratio(self: @TContractState, tick: i129) -> u256;

    // Finds the tick s.t. tick_to_sqrt_ratio(tick) <= sqrt_ratio and tick_to_sqrt_ratio(tick + 1) > sqrt_ratio
    fn sqrt_ratio_to_tick(self: @TContractState, sqrt_ratio: u256) -> i129;
}
