use std::io::{BufRead, BufReader};
use std::path::PathBuf;
use std::process::{Command, Stdio};

use anyhow::Result;
use walkdir::WalkDir;

use crate::config::{AppConfig, ComposeFile, get};
use crate::fs::read;

pub mod alias;
pub mod aliases;
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
pub mod rmi;
pub mod setup;
pub mod up;

pub mod all {
    // re-export flattened subcommands so consuming modules can use wildcard import
    pub use crate::subcommands::alias::*;
    pub use crate::subcommands::aliases::*;
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
    pub use crate::subcommands::rmi::*;
    pub use crate::subcommands::setup::*;
    pub use crate::subcommands::up::*;
}

fn completion_containers() -> Result<Vec<u8>> {
    sys_cmd_output("docker", vec!["ps", "--format", "\"{{.Names}}\""])
}

fn completion_images(with_tags: bool) -> Result<Vec<u8>> {
    match with_tags {
        true => sys_cmd_output("docker", vec!["images", "--format", "{{.Repository}}:{{.Tag}}"]),
        _ => sys_cmd_output("docker", vec!["images", "--format", "{{.Repository}}"]),
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

fn compose(args: Vec<&str>) -> Result<()> {
    let cfiles = configured_yamls();
    let mut cargs = vec!["compose"];

    cfiles.iter().for_each(|file| cargs.append(&mut vec!["-f", file]));
    cargs.append(&mut args.clone());
    docker(cargs)
}

fn configured_yamls() -> Vec<String> {
    match get(&String::from("development.json")) {
        Ok(AppConfig { compose_files, .. }) => compose_files,
        Err(_) => vec!["docker-compose.development.yaml".to_string()],
    }
}

fn docker(args: Vec<&str>) -> Result<()> {
    sys_cmd("docker", args)
}

pub fn get_yaml(filename: &String) -> Result<ComposeFile> {
    let raw = read(PathBuf::from(filename))?;
    let compose: ComposeFile = serde_yaml::from_str(&raw).expect("Could not parse YAML");
    Ok(compose)
}

fn sys_cmd(command: &str, args: Vec<&str>) -> Result<()> {
    // https://rust-lang-nursery.github.io/rust-cookbook/os/external.html#continuously-process-child-process-outputs
    let output = Command::new(command)
        .args(args)
        .stdout(Stdio::piped())
        .stdin(Stdio::piped())
        .spawn()?;

    BufReader::new(output.stdout.expect("Could not pipe to stdout"))
        .lines()
        .filter_map(|line| line.ok())
        .for_each(|line| println!("{}", line));

    Ok(())
}

fn sys_cmd_output(command: &str, args: Vec<&str>) -> Result<Vec<u8>> {
    let output = Command::new(command)
        .args(args)
        .output()?;
    Ok(output.stdout)
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