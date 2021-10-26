use std::path::PathBuf;

use anyhow::Result;
use walkdir::WalkDir;

use crate::config::{AppConfig, ComposeFile, get};
use crate::fs::read;
use crate::term::{external_spawn};
use crate::util::*;

pub mod alias;
pub mod aliases;
pub mod attach;
pub mod build;
pub mod complete;
pub mod config;
pub mod down;
pub mod exec;
pub mod images;
pub mod invoke_alias;
pub mod logs;
pub mod ps;
pub mod psa;
pub mod restart;
pub mod rmi;
pub mod run;
pub mod setup;
pub mod up;

pub mod all {
    // re-export flattened subcommands so consuming modules can use wildcard import
    pub use crate::subcommands::alias::*;
    pub use crate::subcommands::aliases::*;
    pub use crate::subcommands::attach::*;
    pub use crate::subcommands::build::*;
    pub use crate::subcommands::complete::*;
    pub use crate::subcommands::config::*;
    pub use crate::subcommands::down::*;
    pub use crate::subcommands::exec::*;
    pub use crate::subcommands::images::*;
    pub use crate::subcommands::invoke_alias::*;
    pub use crate::subcommands::logs::*;
    pub use crate::subcommands::ps::*;
    pub use crate::subcommands::psa::*;
    pub use crate::subcommands::restart::*;
    pub use crate::subcommands::rmi::*;
    pub use crate::subcommands::run::*;
    pub use crate::subcommands::setup::*;
    pub use crate::subcommands::up::*;
    pub use crate::subcommands::Subcommand;
}

pub trait Subcommand {
    fn process(&self, mode: Option<&String>) -> Result<()>;
}

fn compose(args: Vec<String>, mode: &String) -> Result<()> {
    docker(concat(
        crate::vec_of_strings!["compose"],
        concat(
            configured_yamls(mode).iter()
                .map(|file| crate::vec_of_strings!["-f", file])
                .flatten()
                .collect(),
            args)))
}

fn configured_yamls(mode: &String) -> Vec<String> {
    match get(mode) {
        Ok(AppConfig { compose_files, .. }) => compose_files,
        Err(_) => crate::vec_of_strings![],
    }
}

fn docker(args: Vec<String>) -> Result<()> {
    external_spawn("docker", args)
}

fn get_yaml(filename: &String) -> Result<ComposeFile> {
    let raw = read(PathBuf::from(filename))?;
    let compose: ComposeFile = serde_yaml::from_str(&raw).expect("Could not parse YAML");
    Ok(compose)
}

fn yaml_filenames() -> Result<Vec<String>> {
    let names = WalkDir::new(".")
        .max_depth(1)
        .follow_links(false)
        .into_iter()
        .filter_map(Result::ok)
        .filter(|entry| {
            let f_name = entry.file_name().to_string_lossy();
            f_name.ends_with(".yaml") || f_name.ends_with(".yml")
        })
        .map(|entry| entry.file_name().to_string_lossy().to_string())
        .collect();
    Ok(names)
}
