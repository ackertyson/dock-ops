pub mod alias;
pub mod aliases;
pub mod complete;
pub mod invoke_alias;
pub mod passthru;
pub mod setup;

pub mod all {
    // re-export flattened subcommands so consuming modules can use wildcard import
    pub use crate::subcommands::alias::*;
    pub use crate::subcommands::aliases::*;
    pub use crate::subcommands::complete::*;
    pub use crate::subcommands::invoke_alias::*;
    pub use crate::subcommands::passthru::*;
    pub use crate::subcommands::setup::*;
}
