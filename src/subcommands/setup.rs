use std::collections::HashMap;

use anyhow::Result;
use structopt::StructOpt;
use walkdir::WalkDir;

use crate::config::{AppConfig, get, put};
use crate::subcommands::Subcommand;
use crate::term::show_setup;

#[derive(StructOpt)]
pub struct Setup {}

impl Subcommand for Setup {
    fn process(&self, mode: Option<&String>) -> Result<()> {
        let mode = mode.unwrap();
        let yamls = yaml_filenames()?;
        if yamls.len() == 0 {
            println!("No YAML files found; quitting.");
            return Ok(());
        }

        let AppConfig { compose_files, .. } = get(mode)?;
        let new_files = show_setup(yamls, compose_files, mode)?;
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
