use std::collections::HashMap;

use anyhow::Result;
use structopt::StructOpt;

use crate::config::{AppConfig, get, put};
use crate::subcommands::yaml_filenames;
use crate::term::show_setup;

#[derive(StructOpt)]
pub struct Setup {}

pub fn setup(mode: &String) -> Result<()> {
    let yamls = yaml_filenames()?;
    if yamls.len() == 0 {
        println!("No YAML files found; quitting.");
        return Ok(());
    }

    let new_files = show_setup(yamls, mode)?;
    match new_files.len() > 0 {
        true => {
            match get(mode) {
                Ok(AppConfig { aliases, version, .. }) => {
                    let config = AppConfig {
                        aliases,
                        compose_files: new_files,
                        version
                    };
                    put(mode, config)
                },
                Err(_) => {
                    let config = AppConfig {
                        aliases: HashMap::new(),
                        compose_files: new_files,
                        version: 1,
                    };
                    put(mode, config)
                },
            }
        },
        false => {
            println!("No changes saved.");
            Ok(())
        },
    }
}
