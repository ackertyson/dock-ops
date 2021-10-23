use std::collections::HashMap;
use std::io::{self, Write};

use anyhow::Result;
use structopt::StructOpt;

use crate::config::{AppConfig, get};
use crate::subcommands::{completion_containers, completion_images, completion_services};
use crate::util::*;

#[derive(StructOpt)]
pub struct Complete {
    pub arg: String,
}

// TODO mode flags break completion...
pub fn complete(Complete { arg }: &Complete, mode: &String) -> Result<()> {
    // remove flags/options so they don't F up our math
    let mut args = strip_flags(&arg.split(' ').collect::<Vec<_>>());
    let cmd_slice = args
        .splice(..1, crate::vec_of_strings![])
        .collect::<Vec<_>>();
    let cmd: &str = cmd_slice.get(0).unwrap();

    match args.len() {
        0 => { // $ dock <empty_or_partial_subcommand>_
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
            Ok(io::stdout().write_all(all.join(" ").as_bytes())?)
        },

        1 => match cmd { // $ dock <subcommand> _
            "attach" | "stop" => {
                Ok(io::stdout().write_all(&completion_containers()?)?)
            },
            "rmi" | "tag" => {
                Ok(io::stdout().write_all(&completion_images(true)?)?)
            },
            "build" => {
                Ok(io::stdout().write_all(&completion_images(false)?)?)
            },
            "exec" | "logs" | "restart" | "run" | "up" => {
                Ok(io::stdout().write_all(&completion_services(mode)?.join(" ").as_bytes())?)
            },
            _ => Ok(()), // empty return will invoke shell default completions
        },

        _ => Ok(()), // $ dock <subcommand> <arg> _  (empty return will invoke shell default completions)
    }
}

fn strip_flags(args: &Vec<&str>) -> Vec<String> {
    args.iter()
        .filter(|arg| !arg.starts_with('-'))
        .map(|s| s.to_string())
        .collect()
}
