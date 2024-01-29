use ekubo::types::bounds::{Bounds};
use ekubo::types::i129::{i129};
use ekubo::types::keys::{PoolKey};
use ekubo::types::pool_price::{PoolPrice};
use starknet::{ContractAddress};

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
pub trait IPositions<TStorage> {
    // Update the token URI base of the owned NFT
    fn update_token_uri_base(ref self: TStorage, token_uri_base: felt252);

    // Returns the address of the NFT contract that represents ownership of a position
    fn get_nft_address(self: @TStorage) -> ContractAddress;

    // Returns the principal and fee amount for a set of positions
    fn get_tokens_info(
        self: @TStorage, params: Span<GetTokenInfoRequest>
    ) -> Span<GetTokenInfoResult>;

    // Return the principal and fee amounts owed to a position
    fn get_token_info(
        self: @TStorage, id: u64, pool_key: PoolKey, bounds: Bounds
    ) -> GetTokenInfoResult;

    // Create a new NFT that represents liquidity in a pool. Returns the newly minted token ID
    fn mint(ref self: TStorage, pool_key: PoolKey, bounds: Bounds) -> u64;

    // Same as above but includes a referrer in the emitted event
    fn mint_with_referrer(
        ref self: TStorage, pool_key: PoolKey, bounds: Bounds, referrer: ContractAddress
    ) -> u64;

    // Same as above but includes a referrer in the emitted event
    fn mint_v2(ref self: TStorage, referrer: ContractAddress) -> u64;

    // Delete the NFT. All liquidity controlled by the NFT (not withdrawn) is irrevocably locked.
    // Must be called by an operator, approved address or the owner.
    fn unsafe_burn(ref self: TStorage, id: u64);

    // Deposit in the most recently created token ID. Must be called by an operator, approved address or the owner
    fn deposit_last(
        ref self: TStorage, pool_key: PoolKey, bounds: Bounds, min_liquidity: u128
    ) -> u128;

    // Deposit in a specific token ID. Must be called by an operator, approved address or the owner
    fn deposit(
        ref self: TStorage, id: u64, pool_key: PoolKey, bounds: Bounds, min_liquidity: u128
    ) -> u128;

    // Mint and deposit in a single call
    fn mint_and_deposit(
        ref self: TStorage, pool_key: PoolKey, bounds: Bounds, min_liquidity: u128
    ) -> (u64, u128);

    // Same as above with a referrer
    fn mint_and_deposit_with_referrer(
        ref self: TStorage,
        pool_key: PoolKey,
        bounds: Bounds,
        min_liquidity: u128,
        referrer: ContractAddress
    ) -> (u64, u128);

    // Mint and deposit in a single call, and also clear the tokens
    fn mint_and_deposit_and_clear_both(
        ref self: TStorage, pool_key: PoolKey, bounds: Bounds, min_liquidity: u128
    ) -> (u64, u128, u256, u256);

    // Collect fees for the token ID to the caller. Must be called by an operator, approved address or the owner.
    fn collect_fees(ref self: TStorage, id: u64, pool_key: PoolKey, bounds: Bounds) -> (u128, u128);

    // Withdraw liquidity from a specific token ID to the caller and optionally also collect fees.
    // Must be called by an operator, approved address or the owner.
    // Deprecated: you should call withdraw_v2 instead, and call collect fees separately
    fn withdraw(
        ref self: TStorage,
        id: u64,
        pool_key: PoolKey,
        bounds: Bounds,
        liquidity: u128,
        min_token0: u128,
        min_token1: u128,
        collect_fees: bool
    ) -> (u128, u128);

    // Withdraw liquidity from a specific token ID to the caller. Must be called by an operator, approved address or the owner.
    fn withdraw_v2(
        ref self: TStorage,
        id: u64,
        pool_key: PoolKey,
        bounds: Bounds,
        liquidity: u128,
        min_token0: u128,
        min_token1: u128
    ) -> (u128, u128);

    // Returns the price of a pool after making an empty update to a fake position, which is useful for adding liquidity to extensions
    // with unknown before/after behavior.
    fn get_pool_price(ref self: TStorage, pool_key: PoolKey) -> PoolPrice;
}
