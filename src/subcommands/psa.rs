use anyhow::Result;
use structopt::StructOpt;

use crate::subcommands::docker;

#[derive(StructOpt)]
pub struct Psa {}

pub fn psa() -> Result<()> {
    docker(vec!["ps"])
}
