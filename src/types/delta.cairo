use ekubo::types::i129::{i129};
use core::num::traits::{Zero};

// From the perspective of the core contract, this represents the change in balances.
// For example, swapping 100 token0 for 150 token1 would result in a Delta of { amount0: 100, amount1: -150 }
// Note in case the price limit is reached, the amount0 or amount1_delta may be less than the amount specified in the swap parameters.
#[derive(Copy, Drop, Serde, Debug)]
pub struct Delta {
    pub amount0: i129,
    pub amount1: i129,
}

impl ZeroableDelta of Zero<Delta> {
    fn zero() -> Delta {
        Delta { amount0: Zero::zero(), amount1: Zero::zero() }
    }
    fn is_zero(self: @Delta) -> bool {
        self.amount0.is_zero() & self.amount1.is_zero()
    }
    fn is_non_zero(self: @Delta) -> bool {
        self.amount0.is_non_zero() | self.amount1.is_non_zero()
    }
}

impl DeltaAdd of Add<Delta> {
    fn add(lhs: Delta, rhs: Delta) -> Delta {
        Delta { amount0: lhs.amount0 + rhs.amount0, amount1: lhs.amount1 + rhs.amount1 }
    }
}
impl DeltaSub of Sub<Delta> {
    fn sub(lhs: Delta, rhs: Delta) -> Delta {
        Delta { amount0: lhs.amount0 - rhs.amount0, amount1: lhs.amount1 - rhs.amount1 }
    }
}

impl DeltaAddEq of AddEq<Delta> {
    #[inline(always)]
    fn add_eq(ref self: Delta, other: Delta) {
        self = Add::add(self, other);
    }
}
impl DeltaSubEq of SubEq<Delta> {
    #[inline(always)]
    fn sub_eq(ref self: Delta, other: Delta) {
        self = Sub::sub(self, other);
    }
}
