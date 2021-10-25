use std::collections::HashMap;
use std::io::{self, Write};

use anyhow::Result;
use structopt::{clap::AppSettings, StructOpt};

use crate::config::{AppConfig, get};
use crate::subcommands::{completion_containers, completion_images, completion_services, Subcommand};
use crate::util::*;

#[derive(StructOpt)]
#[structopt(setting = AppSettings::AllowLeadingHyphen)] // to allow mode flags, etc.: $ dock complete "-p my completion args"
pub struct Complete {
    pub arg: String,
}

impl Subcommand for Complete {
    fn process(&self, mode: Option<&String>) -> Result<()> {
        let Complete { arg } = self;
        let mode = mode.unwrap();
        // remove flags/options so they don't F up our math
        let mut args = strip_flags(&arg.split(' ').collect::<Vec<_>>());
        let cmd_slice = args
            .splice(..1, crate::vec_of_strings![])
            .collect::<Vec<_>>();
        let cmd: &str = cmd_slice.get(0).unwrap();

        match args.len() {
            0 => complete_subcommands(&mode), // $ dock <empty_or_partial_subcommand>_
            1 => complete_subcommand_args(cmd, &mode), // $ dock <subcommand> _
            _ => Ok(()), // $ dock <subcommand> <arg> _  (empty return will invoke shell default completions)
        }
    }
}

fn complete_subcommands(mode: &String) -> Result<()> {
    // TODO alias completions do not honor MODE (via completion script)
    let AppConfig { aliases, .. } = match get(mode) {
        Ok(result) => result,
        _ => AppConfig {
            aliases: HashMap::new(),
            compose_files: crate::vec_of_strings![],
            version: 1,
        }
    };

    let builtins = crate::vec_of_strings![
                "alias", "aliases", "attach", "build", "config", "down", "exec", "images", "logs",
                "ps", "psa", "restart", "rmi", "run", "setup", "up"
            ];

    let all = concat(
        builtins,
        aliases.keys().map(String::to_owned).collect());

    // join on "\n" because fish requires it and bash will put up with it
    Ok(io::stdout().write_all(all.join("\n").as_bytes())?)
}

fn complete_subcommand_args(cmd: &str, mode: &String) -> Result<()> {
    // TODO service completions do not honor MODE (via completion script)
    match cmd {
        "attach" | "stop" => {
            Ok(io::stdout().write_all(&completion_containers()?)?)
        },

        "images" | "rmi" | "tag" => {
            Ok(io::stdout().write_all(&completion_images(true)?)?)
        },

        "build" => {
            Ok(io::stdout().write_all(&completion_images(false)?)?)
        },

        "exec" | "logs" | "restart" | "run" | "up" => {
            Ok(io::stdout().write_all(&completion_services(mode)?.join("\n").as_bytes())?)
        },

        _ => Ok(()), // empty return will invoke shell default completions
    }
}

fn strip_flags(args: &Vec<&str>) -> Vec<String> {
    args.iter()
        .filter(|arg| !arg.starts_with("dock"))
        .filter(|arg| !arg.starts_with('-'))
        .map(|s| s.to_string())
        .collect()
}
