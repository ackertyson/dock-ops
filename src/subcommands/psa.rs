use anyhow::Result;
use structopt::StructOpt;

use crate::subcommands::{docker, Subcommand};

#[derive(StructOpt)]
pub struct Psa {}

impl Subcommand for Psa {
    fn process(&self, _mode: Option<&String>) -> Result<()> {
        docker(crate::vec_of_strings!["ps"])
    }
}
