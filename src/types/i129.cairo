use core::array::{ArrayTrait};
use core::option::{Option, OptionTrait};
use core::traits::{Into, TryInto};
use starknet::storage_access::{StorePacking};
use core::num::traits::{Zero};
use core::hash::{HashStateTrait, Hash};

// Represents a signed integer in a 129 bit container, where the sign is 1 bit and the other 128 bits are magnitude
// Note the sign can be true while mag is 0, meaning 1 value is wasted 
// (i.e. sign == true && mag == 0 is redundant with sign == false && mag == 0)
#[derive(Copy, Drop, Serde, Debug)]
pub struct i129 {
    pub mag: u128,
    pub sign: bool,
}

#[generate_trait]
pub impl i129TraitImpl of i129Trait {
    fn is_negative(self: i129) -> bool {
        self.sign & (self.mag.is_non_zero())
    }
}


#[inline(always)]
pub fn i129_new(mag: u128, sign: bool) -> i129 {
    i129 { mag, sign: sign & (mag != 0) }
}

impl i129Zero of Zero<i129> {
    fn zero() -> i129 {
        i129 { mag: 0, sign: false }
    }

    fn is_zero(self: @i129) -> bool {
        self.mag.is_zero()
    }

    fn is_non_zero(self: @i129) -> bool {
        self.mag.is_non_zero()
    }
}

impl u128IntoI129 of Into<u128, i129> {
    fn into(self: u128) -> i129 {
        i129 { mag: self, sign: false }
    }
}

impl i129TryIntoU128 of TryInto<i129, u128> {
    fn try_into(self: i129) -> Option<u128> {
        if (self.is_negative()) {
            Option::None(())
        } else {
            Option::Some(self.mag)
        }
    }
}

#[generate_trait]
pub impl AddDeltaImpl of AddDeltaTrait {
    fn add(self: u128, delta: i129) -> u128 {
        (self.into() + delta).try_into().expect('ADD_DELTA')
    }

    fn sub(self: u128, delta: i129) -> u128 {
        (self.into() - delta).try_into().expect('SUB_DELTA')
    }
}

impl HashI129<S, +HashStateTrait<S>, +Drop<S>> of Hash<i129, S> {
    #[inline(always)]
    fn update_state(state: S, value: i129) -> S {
        let mut hashable: felt252 = value.mag.into();
        if value.is_negative() {
            hashable += 0x100000000000000000000000000000000; // 2**128
        }

        state.update(hashable)
    }
}

impl i129StorePacking of StorePacking<i129, felt252> {
    fn pack(value: i129) -> felt252 {
        assert(value.mag < 0x80000000000000000000000000000000, 'i129_store_overflow');
        if (value.sign) {
            -value.mag.into()
        } else {
            value.mag.into()
        }
    }
    fn unpack(value: felt252) -> i129 {
        if value.into() >= 0x80000000000000000000000000000000_u256 {
            i129_new((-value).try_into().unwrap(), true)
        } else {
            i129_new(value.try_into().unwrap(), false)
        }
    }
}

impl i129Add of Add<i129> {
    fn add(lhs: i129, rhs: i129) -> i129 {
        i129_add(lhs, rhs)
    }
}

impl i129AddEq of AddEq<i129> {
    #[inline(always)]
    fn add_eq(ref self: i129, other: i129) {
        self = Add::add(self, other);
    }
}

impl i129Sub of Sub<i129> {
    fn sub(lhs: i129, rhs: i129) -> i129 {
        i129_sub(lhs, rhs)
    }
}

impl i129SubEq of SubEq<i129> {
    #[inline(always)]
    fn sub_eq(ref self: i129, other: i129) {
        self = Sub::sub(self, other);
    }
}

impl i129Mul of Mul<i129> {
    fn mul(lhs: i129, rhs: i129) -> i129 {
        i129_mul(lhs, rhs)
    }
}

impl i129MulEq of MulEq<i129> {
    #[inline(always)]
    fn mul_eq(ref self: i129, other: i129) {
        self = Mul::mul(self, other);
    }
}

impl i129Div of Div<i129> {
    fn div(lhs: i129, rhs: i129) -> i129 {
        i129_div(lhs, rhs)
    }
}

impl i129DivEq of DivEq<i129> {
    #[inline(always)]
    fn div_eq(ref self: i129, other: i129) {
        self = Div::div(self, other);
    }
}

impl i129PartialEq of PartialEq<i129> {
    fn eq(lhs: @i129, rhs: @i129) -> bool {
        i129_eq(lhs, rhs)
    }

    fn ne(lhs: @i129, rhs: @i129) -> bool {
        !i129_eq(lhs, rhs)
    }
}

impl i129PartialOrd of PartialOrd<i129> {
    #[inline(always)]
    fn le(lhs: i129, rhs: i129) -> bool {
        i129_le(lhs, rhs)
    }

    #[inline(always)]
    fn ge(lhs: i129, rhs: i129) -> bool {
        i129_ge(lhs, rhs)
    }

    #[inline(always)]
    fn lt(lhs: i129, rhs: i129) -> bool {
        i129_lt(lhs, rhs)
    }

    #[inline(always)]
    fn gt(lhs: i129, rhs: i129) -> bool {
        i129_gt(lhs, rhs)
    }
}

impl i129Neg of Neg<i129> {
    #[inline(always)]
    fn neg(a: i129) -> i129 {
        i129_neg(a)
    }
}

fn i129_add(a: i129, b: i129) -> i129 {
    if a.sign == b.sign {
        i129_new(a.mag + b.mag, a.sign)
    } else {
        let (larger, smaller) = if a.mag >= b.mag {
            (a, b)
        } else {
            (b, a)
        };
        let difference = larger.mag - smaller.mag;

        i129_new(difference, larger.sign)
    }
}

#[inline(always)]
fn i129_sub(a: i129, b: i129) -> i129 {
    a + i129_new(b.mag, !b.sign)
}

#[inline(always)]
fn i129_mul(a: i129, b: i129) -> i129 {
    i129_new(a.mag * b.mag, a.sign ^ b.sign)
}

#[inline(always)]
fn i129_div(a: i129, b: i129) -> i129 {
    i129_new(a.mag / b.mag, a.sign ^ b.sign)
}

#[inline(always)]
fn i129_eq(a: @i129, b: @i129) -> bool {
    (a.mag == b.mag) & ((a.sign == b.sign) | (*a.mag == 0))
}

fn i129_gt(a: i129, b: i129) -> bool {
    if (a.sign & !b.sign) {
        return false;
    }
    if (!a.sign & b.sign) {
        // return false iff both are zero
        return (a.mag.is_non_zero()) | (b.mag.is_non_zero());
    }
    if (a.sign & b.sign) {
        return a.mag < b.mag;
    } else {
        return a.mag > b.mag;
    }
}

#[inline(always)]
fn i129_ge(a: i129, b: i129) -> bool {
    (i129_eq(@a, @b) | i129_gt(a, b))
}

#[inline(always)]
fn i129_lt(a: i129, b: i129) -> bool {
    return !i129_ge(a, b);
}

#[inline(always)]
fn i129_le(a: i129, b: i129) -> bool {
    !i129_gt(a, b)
}

#[inline(always)]
fn i129_neg(x: i129) -> i129 {
    i129_new(x.mag, !x.sign)
}
