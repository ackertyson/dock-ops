use std::path::PathBuf;

use anyhow::Result;
use walkdir::WalkDir;

use crate::config::{AppConfig, ComposeFile, get};
use crate::fs::read;
use crate::term::{interactive, sys_cmd, sys_cmd_output};
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
}

pub fn get_yaml(filename: &String) -> Result<ComposeFile> {
    let raw = read(PathBuf::from(filename))?;
    let compose: ComposeFile = serde_yaml::from_str(&raw).expect("Could not parse YAML");
    Ok(compose)
}

fn completion_containers() -> Result<Vec<u8>> {
    sys_cmd_output("docker", crate::vec_of_strings!["ps", "--format", "\"{{.Names}}\""])
}

fn completion_images(with_tags: bool) -> Result<Vec<u8>> {
    match with_tags {
        true => sys_cmd_output("docker", crate::vec_of_strings!["images", "--format", "{{.Repository}}:{{.Tag}}"]),
        _ => sys_cmd_output("docker", crate::vec_of_strings!["images", "--format", "{{.Repository}}"]),
    }
}

fn completion_services() -> Result<Vec<String>> {
    let services = configured_yamls()
        .iter()
        .map(|filename| get_yaml(filename).expect(filename))
        .map(|ComposeFile { services }| services.keys().map(String::from).collect::<Vec<_>>().clone())
        .flatten()
        .collect::<Vec<_>>();
    Ok(services.clone())
}

fn compose(args: Vec<String>) -> Result<()> {
    docker(concat(
        crate::vec_of_strings!["compose"],
        concat(
            configured_yamls().iter().map(|file| crate::vec_of_strings!["-f", file]).flatten().collect(),
            args)))
}

fn configured_yamls() -> Vec<String> {
    match get(&String::from("development.json")) {
        Ok(AppConfig { compose_files, .. }) => compose_files,
        Err(_) => crate::vec_of_strings!["docker-compose.development.yaml".to_string()],
    }
}

fn docker(args: Vec<String>) -> Result<()> {
    interactive("docker", args)?;
    Ok(())
}

fn yaml_filenames() -> Result<Vec<String>> {
    let names = WalkDir::new(".")
        .max_depth(1)
        .follow_links(false)
        .into_iter()
        .filter_map(Result::ok)
        .filter(|entry| {
            let f_name = entry.file_name().to_string_lossy();
            f_name.ends_with(".yaml")
        })
        .map(|entry| entry.file_name().to_string_lossy().to_string())
        .collect();
    Ok(names)
}
