use anyhow::Result;
use structopt::StructOpt;

use crate::config::{AppConfig, get};
use crate::term::color_for_mode;

#[derive(StructOpt)]
pub struct Aliases {}

impl Aliases {
    pub fn process(&self, mode: String) -> Result<()> {
        let AppConfig { aliases, .. } = get(&mode)?;
        let bling = color_for_mode(&mode);
        for (key, val) in aliases.iter() {
            println!("{} => {}", bling.apply_to(key), val);
        }
        Ok(())
    }
}
