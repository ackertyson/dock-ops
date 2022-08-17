use anyhow::Result;
use structopt::StructOpt;

use crate::subcommands::{docker, Subcommand};

#[derive(StructOpt)]
pub struct Clean {}

impl Subcommand for Clean {
    fn process(&self, _mode: Option<&String>) -> Result<()> {
      docker(crate::vec_of_strings!["system", "prune", "-f", "--volumes"])
    }
}
