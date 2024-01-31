use core::array::ArrayTrait;
use core::serde::Serde;
use starknet::storage_access::{StorePacking};
use core::traits::{Into};

// The points at which an extension should be called
#[derive(Copy, Drop, Serde, PartialEq)]
pub struct CallPoints {
    pub after_initialize_pool: bool,
    pub before_swap: bool,
    pub after_swap: bool,
    pub before_update_position: bool,
    pub after_update_position: bool,
}

impl CallPointsDefault of Default<CallPoints> {
    #[inline(always)]
    fn default() -> CallPoints {
        CallPoints {
            after_initialize_pool: false,
            before_swap: false,
            after_swap: false,
            before_update_position: false,
            after_update_position: false,
        }
    }
}

#[inline(always)]
pub fn all_call_points() -> CallPoints {
    CallPoints {
        after_initialize_pool: true,
        before_swap: true,
        after_swap: true,
        before_update_position: true,
        after_update_position: true,
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
        res
    }
}

impl U8TryIntoCallPoints of TryInto<u8, CallPoints> {
    fn try_into(mut self: u8) -> Option<CallPoints> {
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

        let after_update_position = if (self == 8) {
            self -= 8;
            true
        } else {
            false
        };

        if (self == 0) {
            Option::Some(
                CallPoints {
                    after_initialize_pool,
                    before_swap,
                    after_swap,
                    before_update_position,
                    after_update_position,
                }
            )
        } else {
            Option::None(())
        }
    }
}


#[starknet::interface]
trait Interface<T> {
    fn x(self: @T) -> CallPoints;
}

#[starknet::contract]
mod Contract {
    use super::{CallPoints};
    #[storage]
    struct Storage {}

    #[abi(embed_v0)]
    impl Impl of super::Interface<ContractState> {
        fn x(self: @ContractState) -> CallPoints {
            128_u8.try_into().unwrap()
        }
    }
}

