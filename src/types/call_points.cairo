use core::array::{ArrayTrait};
use core::num::traits::{Zero};
use core::serde::{Serde};
use core::traits::{Into};
use starknet::storage_access::{StorePacking};

// The points at which an extension should be called
#[derive(Copy, Drop, Serde, PartialEq, Debug)]
pub struct CallPoints {
    pub before_initialize_pool: bool,
    pub after_initialize_pool: bool,
    pub before_swap: bool,
    pub after_swap: bool,
    pub before_update_position: bool,
    pub after_update_position: bool,
    pub before_collect_fees: bool,
    pub after_collect_fees: bool,
}

impl CallPointsDefault of Default<CallPoints> {
    fn default() -> CallPoints {
        CallPoints {
            before_initialize_pool: false,
            after_initialize_pool: false,
            before_swap: false,
            after_swap: false,
            before_update_position: false,
            after_update_position: false,
            before_collect_fees: false,
            after_collect_fees: false,
        }
    }
}

pub fn all_call_points() -> CallPoints {
    CallPoints {
        before_initialize_pool: true,
        after_initialize_pool: true,
        before_swap: true,
        after_swap: true,
        before_update_position: true,
        after_update_position: true,
        before_collect_fees: true,
        after_collect_fees: true,
    }
}

impl CallPointsIntoU8 of Into<CallPoints, u8> {
    fn into(self: CallPoints) -> u8 {
        let mut res: u8 = 0;
        if (self.after_initialize_pool) {
            res += 128;
        }
        if (self.before_swap) {
            res += 64;
        }
        if (self.after_swap) {
            res += 32;
        }
        if (self.before_update_position) {
            res += 16;
        }
        if (self.after_update_position) {
            res += 8;
        }
        if (self.before_collect_fees) {
            res += 4;
        }
        if (self.after_collect_fees) {
            res += 2;
        }
        if (self.before_initialize_pool) {
            res += 1;
        }
        res
    }
}

impl U8IntoCallPoints of Into<u8, CallPoints> {
    fn into(mut self: u8) -> CallPoints {
        let after_initialize_pool = if (self >= 128) {
            self -= 128;
            true
        } else {
            false
        };

        let before_swap = if (self >= 64) {
            self -= 64;
            true
        } else {
            false
        };

        let after_swap = if (self >= 32) {
            self -= 32;
            true
        } else {
            false
        };

        let before_update_position = if (self >= 16) {
            self -= 16;
            true
        } else {
            false
        };

        let after_update_position = if (self >= 8) {
            self -= 8;
            true
        } else {
            false
        };

        let before_collect_fees = if (self >= 4) {
            self -= 4;
            true
        } else {
            false
        };

        let after_collect_fees = if (self >= 2) {
            self -= 2;
            true
        } else {
            false
        };

        let before_initialize_pool = (self == 1);

        CallPoints {
            before_initialize_pool,
            after_initialize_pool,
            before_swap,
            after_swap,
            before_update_position,
            after_update_position,
            before_collect_fees,
            after_collect_fees,
        }
    }
}

impl CallPointsStorePacking of StorePacking<CallPoints, u8> {
    fn pack(value: CallPoints) -> u8 {
        value.into()
    }
    fn unpack(value: u8) -> CallPoints {
        value.into()
    }
}
