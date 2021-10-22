use anyhow::Result;
use structopt::StructOpt;

use crate::subcommands::compose;

#[derive(StructOpt)]
pub struct Restart {
    pub name: String,
}

pub fn restart(Restart { name }: &Restart) -> Result<()> {
    compose(crate::vec_of_strings!["restart", name])
}
