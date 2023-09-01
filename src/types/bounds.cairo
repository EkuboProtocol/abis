use starknet::ContractAddress;
use ekubo::types::keys::{PositionKey, PoolKey};
use ekubo::types::i129::{i129, i129Trait};
use traits::{Into};
use hash::{LegacyHash};

// Tick bounds for a position
#[derive(Copy, Drop, Serde, PartialEq, Hash)]
struct Bounds {
    lower: i129,
    upper: i129
}
