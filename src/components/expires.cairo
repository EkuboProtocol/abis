use starknet::{get_block_timestamp};

#[starknet::interface]
pub trait IExpires<TContractState> {
    // Reverts if not called before the given timestamp `at`
    fn expires(self: @TContractState, at: u64);
}

#[starknet::embeddable]
pub impl ExpiresImpl<TContractState> of IExpires<TContractState> {
    // Reverts if called after the given time
    fn expires(self: @TContractState, at: u64) {
        assert(get_block_timestamp() < at, 'EXPIRED');
    }
}
