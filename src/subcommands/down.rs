use anyhow::Result;
use structopt::StructOpt;

use crate::subcommands::compose;

#[derive(StructOpt)]
pub struct Down {}

pub fn down() -> Result<()> {
    compose(crate::vec_of_strings!["down", "--remove-orphans"])
}
