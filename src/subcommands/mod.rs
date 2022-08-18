use anyhow::Result;

use crate::config::{AppConfig, get};
use crate::term::{external_spawn};
use crate::util::*;

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

pub fn compose(args: Vec<String>, mode: String) -> Result<()> {
    docker(concat(
        crate::vec_of_strings!["compose"],
        concat(
            configured_yamls(mode).iter()
                .map(|file| crate::vec_of_strings!["-f", file])
                .flatten()
                .collect(),
            args)))
}

fn configured_yamls(mode: String) -> Vec<String> {
    match get(&mode) {
        Ok(AppConfig { compose_files, .. }) => compose_files,
        Err(_) => crate::vec_of_strings![],
    }
}

fn docker(args: Vec<String>) -> Result<()> {
    external_spawn("docker", args)
}
