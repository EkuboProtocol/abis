use starknet::{contract_address_const, ContractAddress};
use core::option::{Option, OptionTrait};
use core::traits::{Into, TryInto};
use ekubo::types::i129::{i129};
use ekubo::types::bounds::{Bounds};

// Uniquely identifies a pool
// token0 is the token with the smaller address (sorted by integer value)
// token1 is the token with the larger address (sorted by integer value)
// fee is specified as a 0.128 number, so 1% == 2**128 / 100
// tick_spacing is the minimum spacing between initialized ticks, i.e. ticks that positions may use
// extension is the address of a contract that implements additional functionality for the pool
#[derive(Copy, Drop, Serde, PartialEq, Hash)]
pub struct PoolKey {
    pub token0: ContractAddress,
    pub token1: ContractAddress,
    pub fee: u128,
    pub tick_spacing: u128,
    pub extension: ContractAddress,
}

// salt is a random number specified by the owner to allow a single address to control many positions with the same pool and bounds
// owner is the immutable address of the position
// bounds is the price range where the liquidity of the position is active
#[derive(Copy, Drop, Serde, PartialEq, Hash)]
pub struct PositionKey {
    pub salt: u64,
    pub owner: ContractAddress,
    pub bounds: Bounds,
}


// owner is the address that owns the saved balance
// token is the address of the token for which the balance is saved
// salt is a random number to allow a single address to own separate saved balances
#[derive(Copy, Drop, Serde, PartialEq, Hash)]
pub struct SavedBalanceKey {
    pub owner: ContractAddress,
    pub token: ContractAddress,
    pub salt: u64,
}
