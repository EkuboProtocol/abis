pub fn serialize<T, +Serde<T>>(t: @T) -> Array<felt252> {
    let mut result: Array<felt252> = ArrayTrait::new();
    Serde::serialize(t, ref result);
    result
}
