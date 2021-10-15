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

fn strip_flags(args: &Vec<&str>) -> Vec<String> {
    args.iter().filter(|arg| !arg.starts_with('-')).map(|s| s.to_string()).collect()
}

pub fn complete(Complete { arg }: &Complete) -> Result<()> {
    let mut args = strip_flags(&arg.split(' ').collect::<Vec<_>>());
    let cmds = args.splice(..1, crate::vec_of_strings![]).collect::<Vec<_>>();
    let cmd: &str = cmds.get(0).unwrap();
    match args.len() {
        0 => { // $ dock <empty_or_partial_subcommand>_
            // TODO missing YAML pushes "no such file" error into cmd completions xD
            let AppConfig { aliases, .. } = get(&String::from("development.json"))?;
            let builtins = crate::vec_of_strings![
                "alias", "aliases", "attach", "build", "config", "down", "exec", "images", "logs",
                "ps", "psa", "restart", "rmi", "run", "setup", "up"
            ];
            let all = concat(builtins, aliases.keys().map(String::to_owned).collect());
            Ok(io::stdout().write_all(all.join(" ").as_bytes())?)
        },
        // TODO accommodate subcommand options: $ dock <subcommand> <options> _
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
                Ok(io::stdout().write_all(&completion_services()?.join(" ").as_bytes())?)
            },
            _ => Ok(()), // empty return will invoke shell default completions
        },
        _ => Ok(()), // $ dock <subcommand> <arg> _  (empty return will invoke shell default completions)
    }
}
