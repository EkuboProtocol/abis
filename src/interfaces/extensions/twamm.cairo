use ekubo::types::fees_per_liquidity::FeesPerLiquidity;
use ekubo::types::i129::i129;
use starknet::ContractAddress;

#[derive(Drop, Copy, Serde, Hash, PartialEq, Debug)]
pub struct OrderKey {
    pub sell_token: ContractAddress,
    pub buy_token: ContractAddress,
    pub fee: u128,
    pub start_time: u64,
    pub end_time: u64,
}

#[derive(Serde, Drop, Copy)]
pub struct StateKey {
    pub token0: ContractAddress,
    pub token1: ContractAddress,
    pub fee: u128,
}

#[derive(Serde, Drop, Copy)]
pub struct OrderInfo {
    pub sale_rate: u128,
    pub remaining_sell_amount: u128,
    pub purchased_amount: u128,
}

#[derive(Drop, Copy, Serde)]
pub struct SaleRateState {
    pub token0_sale_rate: u128,
    pub token1_sale_rate: u128,
    pub last_virtual_order_time: u64,
}

#[derive(Serde, Copy, Drop)]
pub struct UpdateSaleRateCallbackData {
    pub salt: felt252,
    pub order_key: OrderKey,
    pub sale_rate_delta: i129,
}

#[derive(Serde, Copy, Drop)]
pub struct CollectProceedsCallbackData {
    pub salt: felt252,
    pub order_key: OrderKey,
}

#[derive(Serde, Copy, Drop)]
pub enum ForwardCallbackData {
    // Returns an i129 representing the token delta required to update the sale rate, e.g. positive
    // for increases and negative for decreases
    UpdateSaleRate: UpdateSaleRateCallbackData,
    // Returns a u128 representing the amount of proceeds collected
    CollectProceeds: CollectProceedsCallbackData,
}

#[starknet::interface]
pub trait ITWAMM<TContractState> {
    // Return the current state of the given order
    fn get_order_info(
        self: @TContractState, owner: ContractAddress, salt: felt252, order_key: OrderKey,
    ) -> OrderInfo;

    // Returns the current sale rates and the latest time orders executed for the given pool
    fn get_sale_rate_and_last_virtual_order_time(
        self: @TContractState, key: StateKey,
    ) -> SaleRateState;

    // Return the current reward rate
    fn get_reward_rate(self: @TContractState, key: StateKey) -> FeesPerLiquidity;

    // Returns the reward rate stored for the given time
    fn get_time_reward_rate_before(
        self: @TContractState, key: StateKey, time: u64,
    ) -> FeesPerLiquidity;

    // Return the sale rate net for a specific time
    fn get_sale_rate_net(self: @TContractState, key: StateKey, time: u64) -> u128;

    // Return the sale rate delta for a specific time
    fn get_sale_rate_delta(self: @TContractState, key: StateKey, time: u64) -> (i129, i129);

    // Return the next initialized time
    fn next_initialized_time(
        self: @TContractState, key: StateKey, from: u64, max_time: u64,
    ) -> (u64, bool);

    // Execute virtual orders
    fn execute_virtual_orders(ref self: TContractState, key: StateKey);

    // Administrative action to update the call points to the latest version. Anyone can call.
    fn update_call_points(ref self: TContractState);
}
