use anyhow::Result;
use structopt::StructOpt;

use crate::subcommands::compose;

#[derive(StructOpt)]
pub struct Config {}

pub fn config(mode: &String) -> Result<()> {
    compose(crate::vec_of_strings!["config"], mode)
}
