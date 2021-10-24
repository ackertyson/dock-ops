use anyhow::Result;
use structopt::StructOpt;

use crate::config::{AppConfig, get};
use crate::subcommands::Subcommand;
use crate::term::color_for_mode;

#[derive(StructOpt)]
pub struct Aliases {}

impl Subcommand for Aliases {
    fn process(&self, mode: Option<&String>) -> Result<()> {
        let mode = mode.unwrap();
        let AppConfig { aliases, .. } = get(&mode)?;
        let bling = color_for_mode(&mode);
        for (key, val) in aliases.iter() {
            println!("{} => {}", bling.apply_to(key), val);
        }
        Ok(())
    }
}
