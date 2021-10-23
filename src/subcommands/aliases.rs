use anyhow::Result;
use console::style;
use structopt::StructOpt;

use crate::config::{AppConfig, get};

#[derive(StructOpt)]
pub struct Aliases {}

pub fn aliases() -> Result<()> {
    let AppConfig { aliases, .. } = get(&String::from("development.json"))?;
    for (key, val) in aliases.iter() {
        println!("{} => {}", style(key).cyan().bold(), val);
    }
    Ok(())
}
