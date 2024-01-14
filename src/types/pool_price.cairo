use ekubo::types::i129::{i129, i129Trait};
use ekubo::types::call_points::{CallPoints};
use starknet::{StorageBaseAddress, StorePacking};
use zeroable::Zeroable;
use traits::{Into, TryInto};
use option::{OptionTrait, Option};
use integer::{u256_as_non_zero, u128_safe_divmod, u128_as_non_zero, u256_safe_divmod};

#[derive(Copy, Drop, Serde, PartialEq)]
struct PoolPrice {
    // the current ratio, up to 192 bits
    sqrt_ratio: u256,
    // the current tick, up to 32 bits
    tick: i129,
    // the places where the specified extension should be called, 5 bits
    call_points: CallPoints,
}

