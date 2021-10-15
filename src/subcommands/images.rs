use anyhow::Result;
use structopt::StructOpt;

use crate::subcommands::docker;

#[derive(StructOpt)]
pub struct Images {}

pub fn images() -> Result<()> {
    docker(vec!["images"])
}
