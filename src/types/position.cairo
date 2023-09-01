use ekubo::types::fees_per_liquidity::{FeesPerLiquidity};
use zeroable::{Zeroable};
use traits::{Into};

// Represents a liquidity position
// Packed together in a single struct because whenever liquidity changes we typically change fees per liquidity as well
#[derive(Copy, Drop, Serde, starknet::Store)]
struct Position {
    // the amount of liquidity owned by the position
    liquidity: u128,
    // the fee per liquidity inside the tick range of the position, the last time it was computed
    fees_per_liquidity_inside_last: FeesPerLiquidity,
}
