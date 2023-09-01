use starknet::{ClassHash};

#[starknet::interface]
trait IUpgradeable<TStorage> {
    // Update the class hash of the contract.
    fn replace_class_hash(ref self: TStorage, class_hash: ClassHash);
}

