use std::collections::HashMap;
use std::io::{self, Write};
use std::path::PathBuf;

use anyhow::Result;
use structopt::{clap::AppSettings, StructOpt};

use crate::config::{AppConfig, ComposeFile, get};
use crate::subcommands::configured_yamls;
use crate::fs::read;
use crate::term::external_output;
use crate::util::*;

#[derive(StructOpt)]
#[structopt(setting = AppSettings::AllowLeadingHyphen)] // to allow mode flags, etc.: $ dock complete "-p my completion args"
pub struct Complete {
    pub arg: String,
}

impl Complete {
    pub fn process(&self) -> Result<()> {
        let Complete { arg } = self;
        let mode = "development".to_string(); // TODO need to extract this from front of 'arg'
        // remove flags/options so they don't F up our math
        let mut args = strip_flags(&arg.split(' ').collect::<Vec<_>>());
        let cmd_slice = args
            .splice(..1, crate::vec_of_strings![])
            .collect::<Vec<_>>();
        let cmd: &str = cmd_slice.get(0).unwrap();

        match args.len() {
            0 => complete_subcommands(mode), // $ dock <empty_or_partial_subcommand>_
            1 => complete_subcommand_args(cmd, mode), // $ dock <subcommand> _
            _ => Ok(()), // $ dock <subcommand> <arg> _  (empty return will invoke shell default completions)
        }
    }
}

fn completion_containers() -> Result<Vec<u8>> {
    external_output("docker", crate::vec_of_strings!["ps", "--format", "{{.Names}}"])
}

fn completion_images(with_tags: bool) -> Result<Vec<u8>> {
    match with_tags {
        true => external_output("docker", crate::vec_of_strings!["images", "--format", "{{.Repository}}:{{.Tag}}"]),
        _ => external_output("docker", crate::vec_of_strings!["images", "--format", "{{.Repository}}"]),
    }
}

fn completion_services(mode: String) -> Result<Vec<String>> {
    let services = configured_yamls(mode)
        .iter()
        .map(|filename| get_yaml(filename).expect(filename))
        .map(|ComposeFile { services }| services.keys()
            .map(String::from)
            .collect::<Vec<_>>()
            .clone())
        .flatten()
        .collect::<Vec<_>>();
    Ok(services.clone())
}

fn complete_subcommands(mode: String) -> Result<()> {
    // TODO alias completions do not honor MODE (via completion script)
    let AppConfig { aliases, .. } = match get(&mode) {
        Ok(result) => result,
        _ => AppConfig {
            aliases: HashMap::new(),
            compose_files: crate::vec_of_strings![],
            version: 1,
        }
    };

    let builtins = crate::vec_of_strings![
        "alias", "aliases", "attach", "build", "clean", "config", "dbuild", "down", "exec",
        "images", "logs", "ps", "psa", "restart", "rmi", "run", "setup", "stop", "up"
    ];

    let all = concat(
        builtins,
        aliases.keys().map(String::to_owned).collect());

    // join on "\n" (instead of space-delimited) because fish requires it and bash will tolerate it
    Ok(io::stdout().write_all(all.join("\n").as_bytes())?)
}

fn complete_subcommand_args(cmd: &str, mode: String) -> Result<()> {
    // TODO service completions do not honor MODE (via completion script)
    match cmd {
        "attach" => {
            Ok(io::stdout().write_all(&completion_containers()?)?)
        },

        "images" | "rmi" | "tag" => {
            Ok(io::stdout().write_all(&completion_images(true)?)?)
        },

        "dbuild" => {
            Ok(io::stdout().write_all(&completion_images(false)?)?)
        },

        "build" | "exec" | "logs" | "restart" | "run" | "stop" | "up" => {
            Ok(io::stdout().write_all(&completion_services(mode)?.join("\n").as_bytes())?)
        },

        _ => Ok(()), // empty return will invoke shell default completions
    }
}

fn get_yaml(filename: &String) -> Result<ComposeFile> {
    let raw = read(PathBuf::from(filename))?;
    let compose: ComposeFile = serde_yaml::from_str(&raw).expect("Could not parse YAML");
    Ok(compose)
}

fn strip_flags(args: &Vec<&str>) -> Vec<String> {
    args.iter()
        .filter(|arg| !arg.starts_with("dock"))
        .filter(|arg| !arg.starts_with('-'))
        .map(|s| s.to_string())
        .collect()
}
