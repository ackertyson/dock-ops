use std::io::{self, Write};

use anyhow::Result;
use structopt::StructOpt;

use crate::config::{AppConfig, get};
use crate::subcommands::{completion_containers, completion_images, completion_services};

#[derive(StructOpt)]
pub struct Complete {
    pub arg: String,
}

pub fn complete(Complete { arg }: &Complete) -> Result<()> {
    let args = arg.split(' ').collect::<Vec<_>>();
    let cmd: &str = args.get(0).unwrap();
    match args.len() {
        1 => { // command like: $ dock _
            let AppConfig { aliases, .. } = get(&String::from("development.json"))?;
            let builtins = vec![
                "alias", "aliases", "attach", "build", "config", "down", "exec", "images", "logs", "ps", "psa", "rmi", "setup", "up"
            ];
            let mut all = aliases.keys().map(AsRef::as_ref).collect::<Vec<_>>();
            all.append(&mut builtins.clone());
            Ok(io::stdout().write_all(all.join(" ").as_bytes())?)
        },
        2 => match cmd { // command like: $ dock <partial_subcommand> _
            "attach" | "stop" => {
                Ok(io::stdout().write_all(&completion_containers()?)?)
            },
            "rmi" | "tag" => {
                Ok(io::stdout().write_all(&completion_images(true)?)?)
            },
            "build" => {
                Ok(io::stdout().write_all(&completion_images(false)?)?)
            },
            "exec" | "logs" | "run" | "up" => {
                Ok(io::stdout().write_all(&completion_services()?.join(" ").as_bytes())?)
            },
            _ => Ok(()), // empty return will invoke shell default completions
        },
        _ => Ok(()), // command like: $ dock <subcommand> <arg> _  (empty return will invoke shell default completions)
    }
}
