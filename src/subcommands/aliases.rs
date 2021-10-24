use anyhow::Result;
use console::style;
use structopt::StructOpt;

use crate::config::{AppConfig, get};
use crate::subcommands::Subcommand;

#[derive(StructOpt)]
pub struct Aliases {}

impl Subcommand for Aliases {
    fn process(&self, mode: Option<&String>) -> Result<()> {
        let mode = mode.unwrap();
        let AppConfig { aliases, .. } = get(mode)?;
        for (key, val) in aliases.iter() {
            println!("{} => {}", style(key).cyan().bold(), val);
        }
        Ok(())
    }
}

