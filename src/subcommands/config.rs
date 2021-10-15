use anyhow::Result;
use structopt::StructOpt;

use crate::subcommands::compose;

#[derive(StructOpt)]
pub struct Config {}

pub fn config() -> Result<()> {
    compose(vec!["config"])
}
