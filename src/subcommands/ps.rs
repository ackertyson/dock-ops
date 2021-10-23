use anyhow::Result;
use structopt::StructOpt;

use crate::subcommands::compose;

#[derive(StructOpt)]
pub struct Ps {}

pub fn ps(_: &Ps, mode: &String) -> Result<()> {
    compose(crate::vec_of_strings!["ps"], mode)
}
