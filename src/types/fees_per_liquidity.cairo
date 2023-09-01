use traits::{TryInto, Into};
use option::{OptionTrait};
use zeroable::{Zeroable};

#[derive(Copy, Drop, Serde, PartialEq, starknet::Store)]
struct FeesPerLiquidity {
    value0: felt252,
    value1: felt252,
}
