#[derive(Copy, Drop, Serde, PartialEq, starknet::Store)]
pub struct FeesPerLiquidity {
    pub value0: felt252,
    pub value1: felt252,
}
