use core::array::{ArrayTrait};
use core::num::traits::{Zero};
use core::option::{OptionTrait};
use core::serde::Serde;
use ekubo::interfaces::core::{ICoreDispatcher, ICoreDispatcherTrait};
use ekubo::interfaces::erc20::{IERC20Dispatcher, IERC20DispatcherTrait};
use ekubo::types::i129::{i129};
use starknet::{
    get_caller_address, get_contract_address, syscalls::{call_contract_syscall}, ContractAddress,
    SyscallResultTrait
};

fn call_core_with_callback<TInput, TOutput, +Serde<TInput>, +Serde<TOutput>>(
    core: ICoreDispatcher, input: @TInput
) -> TOutput {
    let mut input_data: Array<felt252> = ArrayTrait::new();
    Serde::serialize(input, ref input_data);

    let mut output_span = core.lock(input_data).span();

    Serde::deserialize(ref output_span).expect('DESERIALIZE_RESULT_FAILED')
}

pub fn consume_callback_data<TInput, +Serde<TInput>>(
    core: ICoreDispatcher, callback_data: Array<felt252>
) -> TInput {
    assert(get_caller_address() == core.contract_address, 'CORE_ONLY');
    let mut span = callback_data.span();
    Serde::deserialize(ref span).expect('DESERIALIZE_INPUT_FAILED')
}

pub fn handle_delta(
    core: ICoreDispatcher, token: ContractAddress, delta: i129, recipient: ContractAddress
) {
    if (delta.is_non_zero()) {
        if (delta.sign) {
            core.withdraw(token, recipient, delta.mag);
        } else {
            let token = IERC20Dispatcher { contract_address: token };
            token.approve(core.contract_address, delta.mag.into());
            core.pay(token.contract_address);
        }
    }
}
