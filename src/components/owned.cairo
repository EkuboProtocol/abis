use starknet::{ContractAddress};

#[starknet::interface]
pub trait IOwned<TContractState> {
    // Returns the current owner of the contract
    fn get_owner(self: @TContractState) -> ContractAddress;
    // Transfers the ownership to a new address
    fn transfer_ownership(ref self: TContractState, new_owner: ContractAddress);
}

pub trait Ownable<TContractState> {
    // Initialize the owner of the contract
    fn initialize_owned(ref self: TContractState, owner: ContractAddress);

    // Any ownable contract can require that the owner is calling a particular method
    fn require_owner(self: @TContractState) -> ContractAddress;
}

#[starknet::component]
pub mod Owned {
    use core::num::traits::{Zero};
    use starknet::storage::StoragePointerReadAccess;
    use starknet::storage::StoragePointerWriteAccess;
    use starknet::{get_caller_address, contract_address_const};
    use super::{ContractAddress, IOwned, Ownable};

    #[storage]
    pub struct Storage {
        pub owner: ContractAddress,
    }

    #[derive(starknet::Event, Drop)]
    pub struct OwnershipTransferred {
        pub old_owner: ContractAddress,
        pub new_owner: ContractAddress,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        OwnershipTransferred: OwnershipTransferred
    }


    pub impl OwnableImpl<
        TContractState, +Drop<TContractState>, +HasComponent<TContractState>
    > of Ownable<TContractState> {
        fn initialize_owned(ref self: TContractState, owner: ContractAddress) {
            let mut component = self.get_component_mut();
            let old_owner = component.owner.read();
            component.owner.write(owner);
            component.emit(OwnershipTransferred { old_owner, new_owner: owner });
        }

        fn require_owner(self: @TContractState) -> ContractAddress {
            let owner = self.get_component().get_owner();
            assert(get_caller_address() == owner, 'OWNER_ONLY');
            return owner;
        }
    }

    #[embeddable_as(OwnedImpl)]
    pub impl Owned<
        TContractState, +Drop<TContractState>, +HasComponent<TContractState>
    > of IOwned<ComponentState<TContractState>> {
        fn get_owner(self: @ComponentState<TContractState>) -> ContractAddress {
            self.owner.read()
        }

        fn transfer_ownership(
            ref self: ComponentState<TContractState>, new_owner: ContractAddress
        ) {
            let old_owner = self.get_contract().require_owner();
            self.owner.write(new_owner);
            self.emit(OwnershipTransferred { old_owner, new_owner });
        }
    }
}
