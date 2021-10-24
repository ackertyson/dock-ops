use anyhow::Result;
use structopt::StructOpt;

use crate::subcommands::{docker, Subcommand};

#[derive(StructOpt)]
pub struct Rmi {
    pub name: String,
}

impl Subcommand for Rmi {
    fn process(&self, _mode: Option<&String>) -> Result<()> {
        let Rmi { name } = self;
        docker(crate::vec_of_strings!["rmi", name])
    }
}
