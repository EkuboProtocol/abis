use ekubo::types::i129::i129;
use starknet::ContractAddress;

#[derive(Drop, Copy, Serde, Hash, PartialEq, Debug)]
pub struct OrderKey {
    // The first token sorted by address
    pub token0: ContractAddress,
    // The second token sorted by address
    pub token1: ContractAddress,
    // The price at which the token should be bought/sold. Must be a multiple of tick spacing.
    // If the specified tick is evenly divisible by 2 * tick_spacing, it implies that the order is
    // selling token0. Otherwise, it is selling token1.
    pub tick: i129,
}

// State of a particular order, stored separately per (owner, salt, order key)
#[derive(Drop, Copy, Serde, PartialEq, Debug)]
pub(crate) struct OrderState {
    // Snapshot of the pool's initialized_ticks_crossed when the order was created
    pub initialized_ticks_crossed_snapshot: u64,
    // How much liquidity was deposited for this order
    pub liquidity: u128,
}


// The state of the pool as it was last seen
#[derive(Drop, Copy, Serde, PartialEq)]
pub(crate) struct PoolState {
    // The number of times this pool has crossed an initialized tick plus one
    pub initialized_ticks_crossed: u64,
    // The last tick that was seen for the pool
    pub last_tick: i129,
}


#[derive(Drop, Copy, Serde, PartialEq, Debug)]
pub struct GetOrderInfoRequest {
    pub owner: ContractAddress,
    pub salt: felt252,
    pub order_key: OrderKey,
}

#[derive(Drop, Copy, Serde, PartialEq, Debug)]
pub struct GetOrderInfoResult {
    pub(crate) state: OrderState,
    pub executed: bool,
    pub amount0: u128,
    pub amount1: u128,
}

// One of the enum options that can be passed through to `Core#forward` to create a new limit order
// with a given key and liquidity
#[derive(Drop, Copy, Serde)]
pub struct PlaceOrderForwardCallbackData {
    pub salt: felt252,
    pub order_key: OrderKey,
    pub liquidity: u128,
}

// One of the enum options that can be passed through to `Core#forward` to close an order with the
// given key
#[derive(Drop, Copy, Serde)]
pub struct CloseOrderForwardCallbackData {
    pub salt: felt252,
    pub order_key: OrderKey,
}

// Pass to `Core#forward` to interact with limit orders placed via this extension
#[derive(Drop, Copy, Serde)]
pub enum ForwardCallbackData {
    PlaceOrder: PlaceOrderForwardCallbackData,
    CloseOrder: CloseOrderForwardCallbackData,
}

// Returns the amount of {token0,token1} that must be paid to cover the order
pub type PlaceOrderForwardCallbackResult = u128;
// The amount of token0 and token1 received for closing the order
pub type CloseOrderForwardCallbackResult = (u128, u128);

#[starknet::interface]
pub trait ILimitOrders<TContractState> {
    // Return information on a single order
    fn get_order_info(self: @TContractState, request: GetOrderInfoRequest) -> GetOrderInfoResult;

    // Return information on each of the given orders
    fn get_order_infos(
        self: @TContractState, requests: Span<GetOrderInfoRequest>,
    ) -> Span<GetOrderInfoResult>;
}
