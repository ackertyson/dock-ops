use anyhow::Result;
use console::style;
use structopt::StructOpt;

use crate::config::{AppConfig, get};

#[derive(StructOpt)]
pub struct Aliases {}

pub fn aliases() -> Result<()> {
    match get(&String::from("development.json")) {
        Ok(AppConfig { aliases, .. }) => {
            for (key, val) in aliases.iter() {
                println!("{} => {}", style(key).cyan().bold(), val);
            }
            Ok(())
        },
        Err(_) => Ok(()),
    }
}
