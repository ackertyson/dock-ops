use anyhow::Result;
use structopt::StructOpt;

use crate::subcommands::docker;

#[derive(StructOpt)]
pub struct Images {}

pub fn images() -> Result<()> {
    docker(crate::vec_of_strings!["images"])
}
