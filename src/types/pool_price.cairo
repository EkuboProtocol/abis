use ekubo::types::i129::{i129};
use ekubo::types::call_points::{CallPoints};

#[derive(Copy, Drop, Serde, PartialEq)]
pub struct PoolPrice {
    // the current ratio, up to 192 bits
    pub sqrt_ratio: u256,
    // the current tick, up to 32 bits
    pub tick: i129,
}

