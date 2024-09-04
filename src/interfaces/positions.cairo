use ekubo::extensions::interfaces::twamm::{OrderKey, OrderInfo};
use ekubo::types::bounds::{Bounds};
use ekubo::types::keys::{PoolKey};
use ekubo::types::pool_price::{PoolPrice};
use starknet::{ContractAddress, ClassHash};

#[derive(Copy, Drop, Serde, PartialEq)]
pub struct GetTokenInfoResult {
    pub pool_price: PoolPrice,
    pub liquidity: u128,
    pub amount0: u128,
    pub amount1: u128,
    pub fees0: u128,
    pub fees1: u128,
}

#[derive(Copy, Drop, Serde)]
pub struct GetTokenInfoRequest {
    pub id: u64,
    pub pool_key: PoolKey,
    pub bounds: Bounds
}

#[starknet::interface]
pub trait IPositions<TContractState> {
    // Returns the address of the NFT contract that represents ownership of a position
    fn get_nft_address(self: @TContractState) -> ContractAddress;

    // Upgrades the classhash of the nft
    fn upgrade_nft(ref self: TContractState, class_hash: ClassHash);

    // Set the contract address of the twamm
    fn set_twamm(ref self: TContractState, twamm_address: ContractAddress);

    // Returns the twamm contract address
    fn get_twamm_address(self: @TContractState) -> ContractAddress;

    // Returns the principal and fee amount for a set of positions
    fn get_tokens_info(
        self: @TContractState, params: Span<GetTokenInfoRequest>
    ) -> Span<GetTokenInfoResult>;

    // Return the principal and fee amounts owed to a position
    fn get_token_info(
        self: @TContractState, id: u64, pool_key: PoolKey, bounds: Bounds
    ) -> GetTokenInfoResult;

    // Returns the sale rate, remaining sell amount and purchased amount for a set of orders
    fn get_orders_info(self: @TContractState, params: Span<(u64, OrderKey)>) -> Span<OrderInfo>;

    // Returns the sale rate, remaining sell amount and purchased amount for an order
    fn get_order_info(self: @TContractState, id: u64, order_key: OrderKey) -> OrderInfo;

    // Create a new NFT that represents liquidity in a pool. Returns the newly minted token ID
    // This function is deprecated. The pool_key and bounds arguments are not used. Instead, use
    // mint_v2.
    fn mint(ref self: TContractState, pool_key: PoolKey, bounds: Bounds) -> u64;

    // Same as above but includes a referrer in the emitted event
    // This function is deprecated. The pool_key and bounds arguments are not used. Instead, use
    // mint_v2.
    fn mint_with_referrer(
        ref self: TContractState, pool_key: PoolKey, bounds: Bounds, referrer: ContractAddress
    ) -> u64;

    // Mint an NFT that can be used for creating liquidity positions.
    fn mint_v2(ref self: TContractState, referrer: ContractAddress) -> u64;

    // Checks that liquidity is zero for the given token ID and pool_key/bounds. Helps prevent burns
    // of NFTs that have non-zero liquidity.
    fn check_liquidity_is_zero(self: @TContractState, id: u64, pool_key: PoolKey, bounds: Bounds);

    // Delete the NFT. All liquidity controlled by the NFT (not withdrawn) is irrevocably locked.
    // Must be called by an operator, approved address or the owner.
    fn unsafe_burn(ref self: TContractState, id: u64);

    // Deposit in the most recently created token ID. Must be called by an operator, approved
    // address or the owner
    fn deposit_last(
        ref self: TContractState, pool_key: PoolKey, bounds: Bounds, min_liquidity: u128
    ) -> u128;

    // Deposit the specified amounts in the most recently created token ID. Must be called by an
    // operator, approved address or the owner
    fn deposit_amounts_last(
        ref self: TContractState,
        pool_key: PoolKey,
        bounds: Bounds,
        amount0: u128,
        amount1: u128,
        min_liquidity: u128
    ) -> u128;

    // Deposit in a specific token ID. Must be called by an operator, approved address or the owner
    fn deposit(
        ref self: TContractState, id: u64, pool_key: PoolKey, bounds: Bounds, min_liquidity: u128
    ) -> u128;

    // Deposit the specified amounts of token0 and token1 into the position with the specified ID.
    // Must be called by an operator, approved address or the owner.
    fn deposit_amounts(
        ref self: TContractState,
        id: u64,
        pool_key: PoolKey,
        bounds: Bounds,
        amount0: u128,
        amount1: u128,
        min_liquidity: u128
    ) -> u128;

    // Mint and deposit in a single call
    fn mint_and_deposit(
        ref self: TContractState, pool_key: PoolKey, bounds: Bounds, min_liquidity: u128
    ) -> (u64, u128);

    // Same as above with a referrer
    fn mint_and_deposit_with_referrer(
        ref self: TContractState,
        pool_key: PoolKey,
        bounds: Bounds,
        min_liquidity: u128,
        referrer: ContractAddress
    ) -> (u64, u128);

    // Mint and deposit in a single call, and also clear the tokens
    fn mint_and_deposit_and_clear_both(
        ref self: TContractState, pool_key: PoolKey, bounds: Bounds, min_liquidity: u128
    ) -> (u64, u128, u256, u256);

    // Collect fees for the token ID to the caller. Must be called by an operator, approved address
    // or the owner.
    fn collect_fees(
        ref self: TContractState, id: u64, pool_key: PoolKey, bounds: Bounds
    ) -> (u128, u128);

    // Withdraw liquidity from a specific token ID to the caller and optionally also collect fees.
    // Must be called by an operator, approved address or the owner.
    // Deprecated: you should call withdraw_v2 instead, and call collect fees separately
    fn withdraw(
        ref self: TContractState,
        id: u64,
        pool_key: PoolKey,
        bounds: Bounds,
        liquidity: u128,
        min_token0: u128,
        min_token1: u128,
        collect_fees: bool
    ) -> (u128, u128);

    // Withdraw liquidity from a specific token ID to the caller. Must be called by an operator,
    // approved address or the owner.
    fn withdraw_v2(
        ref self: TContractState,
        id: u64,
        pool_key: PoolKey,
        bounds: Bounds,
        liquidity: u128,
        min_token0: u128,
        min_token1: u128
    ) -> (u128, u128);

    // Returns the price of a pool after making an empty update to a fake position, which is useful
    // for adding liquidity to extensions with unknown before/after behavior.
    fn get_pool_price(self: @TContractState, pool_key: PoolKey) -> PoolPrice;

    // Mint a TWAMM order and increase sold amount, returning the minted token ID and the computed
    // sale rate of the order.
    fn mint_and_increase_sell_amount(
        ref self: TContractState, order_key: OrderKey, amount: u128
    ) -> (u64, u128);

    // Increase the sell amount of the last minted NFT, returning the amount by which the order's
    // sale rate was increased.
    fn increase_sell_amount_last(
        ref self: TContractState, order_key: OrderKey, amount: u128
    ) -> u128;

    // Increase sold amount on a TWAMM order, returning the amount by which the order's sale rate
    // was increased.
    fn increase_sell_amount(
        ref self: TContractState, id: u64, order_key: OrderKey, amount: u128
    ) -> u128;

    // Decrease sold amount on a TWAMM position and send the remaining amount to the given recipient
    // address. Returns the amount transferred.
    fn decrease_sale_rate_to(
        ref self: TContractState,
        id: u64,
        order_key: OrderKey,
        sale_rate_delta: u128,
        recipient: ContractAddress
    ) -> u128;

    // Decrease sold amount on a TWAMM position and send the remaining amount to the caller.
    fn decrease_sale_rate_to_self(
        ref self: TContractState, id: u64, order_key: OrderKey, sale_rate_delta: u128
    ) -> u128;

    // Withdraws proceeds from a TWAMM position and send the proceeds to the caller.
    fn withdraw_proceeds_from_sale_to_self(
        ref self: TContractState, id: u64, order_key: OrderKey
    ) -> u128;

    // Withdraws proceeds from a TWAMM position and send the proceeds to the given recipient
    // address. Returns the amount of proceeds withdrawn.
    fn withdraw_proceeds_from_sale_to(
        ref self: TContractState, id: u64, order_key: OrderKey, recipient: ContractAddress
    ) -> u128;
}
