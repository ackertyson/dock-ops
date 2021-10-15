use std::collections::HashMap;

use anyhow::Result;
use structopt::StructOpt;

use crate::config::{AppConfig, get, put};
use crate::subcommands::yaml_filenames;
use crate::term::show_setup;

#[derive(StructOpt)]
pub struct Setup {}

pub fn setup() -> Result<()> {
    let yamls = yaml_filenames()?;
    if yamls.len() == 0 {
        println!("No YAML files found; quitting.");
        return Ok(());
    }

    let new_files = show_setup(yamls)?;
    match new_files.len() > 0 {
        true => {
            match get(&String::from("development.json")) {
                Ok(AppConfig { aliases, version, .. }) => {
                    let config = AppConfig {
                        aliases,
                        compose_files: new_files,
                        version
                    };
                    put(&String::from("development.json"), config)
                },
                Err(_) => {
                    let config = AppConfig {
                        aliases: HashMap::new(),
                        compose_files: new_files,
                        version: 1,
                    };
                    put(&String::from("development.json"), config)
                },
            }
        },
        false => {
            println!("No changes saved.");
            Ok(())
        },
    }
}
