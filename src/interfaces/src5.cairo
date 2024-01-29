// IDs of interfaces for ERC165, for backwards compatibility
pub const ERC165_ERC721_ID: felt252 = 0x80ac58cd;
pub const ERC165_ERC721_METADATA_ID: felt252 = 0x5b5e139f;
// https://eips.ethereum.org/EIPS/eip-165#how-to-detect-if-a-contract-implements-erc-165
pub const ERC165_ERC165_ID: felt252 = 0x01ffc9a7;

// https://github.com/starknet-io/SNIPs/blob/main/SNIPS/snip-5.md#how-to-detect-if-a-contract-implements-src-5
pub const SRC5_SRC5_ID: felt252 = 0x3f918d17e5ee77373b56385708f855659a07f75997f365cf87748628532a055;

// https://github.com/OpenZeppelin/cairo-contracts/blob/495ed8a66cc6f3e6ca7eb8cb741ff4eba2265807/src/token/erc721/interface.cairo#L7-L11
pub const SRC5_ERC721_ID: felt252 =
    0x33eb2f84c309543403fd69f0d0f363781ef06ef6faeb0131ff16ea3175bd943;
pub const SRC5_ERC721_METADATA_ID: felt252 =
    0x6069a70848f907fa57668ba1875164eb4dcee693952468581406d131081bbd;

#[starknet::interface]
pub trait ISRC5<TStorage> {
    // Returns true if the contract supports the interface
    // Note this is backwards compatible with the old spec that took a u32, since they
    // share a selector
    fn supportsInterface(self: @TStorage, interfaceId: felt252) -> bool;

    // snake_case
    fn supports_interface(self: @TStorage, interface_id: felt252) -> bool;
}
