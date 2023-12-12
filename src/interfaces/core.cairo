use starknet::{ContractAddress, ClassHash};
use ekubo::types::pool_price::{PoolPrice};
use ekubo::types::position::{Position};
use ekubo::types::fees_per_liquidity::{FeesPerLiquidity};
use ekubo::types::keys::{PositionKey, PoolKey, SavedBalanceKey};
use ekubo::types::i129::{i129};
use ekubo::types::bounds::{Bounds};
use ekubo::types::delta::{Delta};
use ekubo::types::call_points::{CallPoints};

// This interface must be implemented by any contract that intends to call ICore#lock
#[starknet::interface]
trait ILocker<TStorage> {
    // This function is called on the caller of lock, i.e. a callback
    // The input is the data passed to ICore#lock, the output is passed back through as the return value of #lock
    fn locked(ref self: TStorage, id: u32, data: Array<felt252>) -> Array<felt252>;
}

// Passed as an argument to update a position. The owner of the position is implicitly the locker.
// bounds is the lower and upper price range of the position, expressed in terms of log base sqrt 1.000001 of token1/token0.
// liquidity_delta is how the position's liquidity should be updated.
#[derive(Copy, Drop, Serde)]
struct UpdatePositionParameters {
    salt: u64,
    bounds: Bounds,
    liquidity_delta: i129,
}

// The amount is the amount of token0 or token1 to swap, depending on is_token1. A negative amount implies an exact-output swap.
// is_token1 Indicates whether the amount is in terms of token0 or token1.
// sqrt_ratio_limit is a limit on how far the price can move as part of the swap. Note this must always be specified, and must be between the maximum and minimum sqrt ratio.
// skip_ahead is an optimization parameter for large swaps across many uninitialized ticks to reduce the number of swap iterations that must be performed
#[derive(Copy, Drop, Serde)]
struct SwapParameters {
    amount: i129,
    is_token1: bool,
    sqrt_ratio_limit: u256,
    skip_ahead: u32,
}

// Details about a liquidity position. Note the position may not exist, i.e. a position may be returned that has never had non-zero liquidity.
// Note you should not rely on fees per liquidity inside to be consistent across calls, since it also is used to track accumulated fees over time
#[derive(Copy, Drop, Serde)]
struct GetPositionWithFeesResult {
    position: Position,
    fees0: u128,
    fees1: u128,
    // the current value of fees per liquidity inside is required to compute the fees, so it is also returned to save computation
    fees_per_liquidity_inside_current: FeesPerLiquidity,
}

// The current state of the queried locker
#[derive(Copy, Drop, Serde)]
struct LockerState {
    address: ContractAddress,
    nonzero_delta_count: u32
}

// An extension is an optional contract that can be specified as part of a pool key to modify pool behavior
#[starknet::interface]
trait IExtension<TStorage> {
    // Called before a pool is initialized, and returns where the extension should be called in future operations
    fn before_initialize_pool(
        ref self: TStorage, caller: ContractAddress, pool_key: PoolKey, initial_tick: i129
    ) -> CallPoints;
    // Called after a pool is initialized
    fn after_initialize_pool(
        ref self: TStorage, caller: ContractAddress, pool_key: PoolKey, initial_tick: i129
    );

    // Called before a swap happens
    fn before_swap(
        ref self: TStorage, caller: ContractAddress, pool_key: PoolKey, params: SwapParameters
    );
    // Called after a swap happens with the result of the swap
    fn after_swap(
        ref self: TStorage,
        caller: ContractAddress,
        pool_key: PoolKey,
        params: SwapParameters,
        delta: Delta
    );

    // Called before an update to a position
    fn before_update_position(
        ref self: TStorage,
        caller: ContractAddress,
        pool_key: PoolKey,
        params: UpdatePositionParameters
    );
    // Called after the position is updated with the result of the update
    fn after_update_position(
        ref self: TStorage,
        caller: ContractAddress,
        pool_key: PoolKey,
        params: UpdatePositionParameters,
        delta: Delta
    );
}

#[starknet::interface]
trait ICore<TStorage> {
    // Sets the contract to withdrawals only mode, thus preventing any new capital being sent to the contract
    fn set_withdrawal_only_mode(ref self: TStorage);

    // Returns whether the contract is in withdrawal only mode
    fn get_withdrawal_only_mode(self: @TStorage) -> bool;

    // Get the amount of withdrawal fees collected for the protocol
    fn get_protocol_fees_collected(self: @TStorage, token: ContractAddress) -> u128;

    // Get the state of the locker with the given ID
    fn get_locker_state(self: @TStorage, id: u32) -> LockerState;

    // Get the price of the pool
    fn get_pool_price(self: @TStorage, pool_key: PoolKey) -> PoolPrice;

    // Get the liquidity of the pool
    fn get_pool_liquidity(self: @TStorage, pool_key: PoolKey) -> u128;

    // Get the current all-time fees per liquidity for the pool
    fn get_pool_fees_per_liquidity(self: @TStorage, pool_key: PoolKey) -> FeesPerLiquidity;

    // Get the fees per liquidity inside a given tick range for a pool
    fn get_pool_fees_per_liquidity_inside(
        self: @TStorage, pool_key: PoolKey, bounds: Bounds
    ) -> FeesPerLiquidity;

    // Get the liquidity delta for the tick of the given pool
    fn get_pool_tick_liquidity_delta(self: @TStorage, pool_key: PoolKey, index: i129) -> i129;

    // Get the net liquidity referencing a tick for the given pool
    fn get_pool_tick_liquidity_net(self: @TStorage, pool_key: PoolKey, index: i129) -> u128;

    // Get the fees on the other side of the tick from the current tick
    fn get_pool_tick_fees_outside(
        self: @TStorage, pool_key: PoolKey, index: i129
    ) -> FeesPerLiquidity;

    // Get the state of a given position for the given pool
    fn get_position(self: @TStorage, pool_key: PoolKey, position_key: PositionKey) -> Position;

    // Get the state of a given position for the given pool including the calculated fees
    fn get_position_with_fees(
        self: @TStorage, pool_key: PoolKey, position_key: PositionKey
    ) -> GetPositionWithFeesResult;

    // Get the last recorded balance of a token for core, used by core for computing payment amounts
    fn get_reserves(self: @TStorage, token: ContractAddress) -> u256;

    // Get the balance that is saved in core for a given account for use in a future lock (i.e. methods #save and #load)
    fn get_saved_balance(self: @TStorage, key: SavedBalanceKey) -> u128;

    // Return the next initialized tick from the given tick, i.e. the initialized tick that is greater than the given `from` tick
    fn next_initialized_tick(
        self: @TStorage, pool_key: PoolKey, from: i129, skip_ahead: u32
    ) -> (i129, bool);

    // Return the previously initialized tick from the given tick, i.e. the initialized tick that is less than or equal to the given `from` tick
    // Note this can also be used to check if the tick is initialized
    fn prev_initialized_tick(
        self: @TStorage, pool_key: PoolKey, from: i129, skip_ahead: u32
    ) -> (i129, bool);

    // Withdraws any fees collected by the contract (only the owner can call this function)
    fn withdraw_protocol_fees(
        ref self: TStorage, recipient: ContractAddress, token: ContractAddress, amount: u128
    );

    // Locks the core contract, allowing other functions to be called that require locking.
    // The lock callback is called with the input data, and the returned array is passed through to the caller.
    fn lock(ref self: TStorage, data: Array<felt252>) -> Array<felt252>;

    // Withdraws a given token from core. This is used to withdraw the output of swaps or burnt liquidity, and also for flash loans.
    // Must be called within a ILocker#locked
    fn withdraw(
        ref self: TStorage, token_address: ContractAddress, recipient: ContractAddress, amount: u128
    );

    // Save a given token balance in core for a given account for use in a future lock. It can be recalled by calling load.
    // Must be called within a ILocker#locked by the locker
    // Returns the next saved balance for the given key
    fn save(ref self: TStorage, key: SavedBalanceKey, amount: u128) -> u128;

    // Deposit a given token into core. This is how payments are made. First send the token to core, and then call deposit to account the delta.
    // Must be called within a ILocker#locked
    fn deposit(ref self: TStorage, token_address: ContractAddress) -> u128;

    // Recall a balance previously saved via #save
    // Must be called within a ILocker#locked, but it can be called by addresses other than the locker
    // Returns the next saved balance for the given key
    fn load(ref self: TStorage, token: ContractAddress, salt: u64, amount: u128) -> u128;

    // Initialize a pool. This can happen outside of a lock callback because it does not require any tokens to be spent.
    fn initialize_pool(ref self: TStorage, pool_key: PoolKey, initial_tick: i129) -> u256;

    // Initialize a pool if it's not already initialized. Useful as part of a batch of other operations.
    fn maybe_initialize_pool(
        ref self: TStorage, pool_key: PoolKey, initial_tick: i129
    ) -> Option<u256>;

    // Update a liquidity position in a pool. The owner of the position is always the locker.
    // Must be called within a ILocker#locked. Note also that a position cannot be burned to 0 unless all fees have been collected
    fn update_position(
        ref self: TStorage, pool_key: PoolKey, params: UpdatePositionParameters
    ) -> Delta;

    // Collect the fees owed on a position
    fn collect_fees(ref self: TStorage, pool_key: PoolKey, salt: u64, bounds: Bounds) -> Delta;

    // Make a swap against a pool.
    // You must call this within a lock callback.
    fn swap(ref self: TStorage, pool_key: PoolKey, params: SwapParameters) -> Delta;

    // Accumulates tokens to fees of a pool. 
    // This is useful for extensions, e.g. extensions that do arbitrage based on external data and want to return profits to in-range LPs
    // You must call this within a lock callback.
    fn accumulate_as_fees(
        ref self: TStorage, pool_key: PoolKey, amount0: u128, amount1: u128
    ) -> Delta;
}
