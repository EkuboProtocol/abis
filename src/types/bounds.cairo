use ekubo::types::i129::{i129};

// Tick bounds for a position
#[derive(Copy, Drop, Serde, PartialEq, Hash)]
pub struct Bounds {
    pub lower: i129,
    pub upper: i129
}
