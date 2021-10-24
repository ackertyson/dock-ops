use anyhow::Result;
use structopt::{clap::AppSettings, StructOpt};

use crate::config::{AppConfig, get, put};
use crate::subcommands::Subcommand;

#[derive(StructOpt)]
#[structopt(setting = AppSettings::TrailingVarArg)]
pub struct Alias {
    #[structopt(short, long)]
    pub delete: bool,
    pub name: String,
    #[structopt(conflicts_with("delete"))]
    pub args: Vec<String>,
}

impl Subcommand for Alias {
    fn process(&self, mode: Option<&String>) -> Result<()> {
        let Alias { name, delete, args } = self;
        let mode = mode.unwrap();
        let AppConfig { mut aliases, compose_files, version } = get(&mode)?;
        match delete {
            true => {
                aliases.remove(&name.to_string());
                let config = AppConfig {
                    aliases,
                    compose_files,
                    version
                };
                put(&mode, config)
            },
            _ => {
                aliases.insert(name.to_string(), args.join(" "));
                let config = AppConfig {
                    aliases,
                    compose_files,
                    version
                };
                put(&mode, config)
            }
        }
    }
}
