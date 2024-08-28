use starknet::{ClassHash};

#[starknet::interface]
pub trait IUpgradeable<TStorage> {
    // Update the class hash of the contract.
    fn replace_class_hash(ref self: TStorage, class_hash: ClassHash);
}

// Any contract that is upgradeable must implement this
#[starknet::interface]
pub trait IHasInterface<TContractState> {
    fn get_primary_interface_id(self: @TContractState) -> felt252;
}

#[starknet::component]
pub mod Upgradeable {
    use core::array::SpanTrait;
    use core::num::traits::{Zero};
    use core::result::ResultTrait;
    use ekubo::components::owned::{Ownable};
    use super::{IUpgradeable};
    use starknet::{ClassHash, syscalls::{replace_class_syscall, library_call_syscall}};
    use super::{IHasInterface};

    #[storage]
    pub struct Storage {}

    #[derive(starknet::Event, Drop)]
    pub struct ClassHashReplaced {
        pub new_class_hash: ClassHash,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        ClassHashReplaced: ClassHashReplaced
    }


    #[embeddable_as(UpgradeableImpl)]
    pub impl Upgradeable<
        TContractState,
        +HasComponent<TContractState>,
        +IHasInterface<TContractState>,
        +Ownable<TContractState>,
    > of IUpgradeable<ComponentState<TContractState>> {
        fn replace_class_hash(ref self: ComponentState<TContractState>, class_hash: ClassHash) {
            let this_contract = self.get_contract();
            this_contract.require_owner();
            assert(!class_hash.is_zero(), 'INVALID_CLASS_HASH');

            let id = this_contract.get_primary_interface_id();

            let mut result = library_call_syscall(
                class_hash, selector!("get_primary_interface_id"), array![].span()
            )
                .expect('MISSING_PRIMARY_INTERFACE_ID');

            let next_id = result.pop_front().expect('INVALID_RETURN_DATA');

            assert(@id == next_id, 'UPGRADEABLE_ID_MISMATCH');

            replace_class_syscall(class_hash).expect('UPGRADE_FAILED');

            self.emit(ClassHashReplaced { new_class_hash: class_hash });
        }
    }
}
