use starknet::ContractAddress;
use ekubo::types::keys::{PositionKey, PoolKey};
use ekubo::types::i129::{i129, i129Trait};
use core::traits::{Into};

// Tick bounds for a position
#[derive(Copy, Drop, Serde, PartialEq, Hash)]
pub struct Bounds {
    pub lower: i129,
    pub upper: i129
}
