use anyhow::Result;
use structopt::StructOpt;

use crate::subcommands::docker;

#[derive(StructOpt)]
pub struct Rmi {
    pub name: String,
}

pub fn rmi(Rmi { name }: &Rmi) -> Result<()> {
    docker(crate::vec_of_strings!["rmi", name])
}
