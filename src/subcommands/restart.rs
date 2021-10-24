use anyhow::Result;
use structopt::StructOpt;

use crate::subcommands::{compose, Subcommand};

#[derive(StructOpt)]
pub struct Restart {
    pub name: String,
}

impl Subcommand for Restart {
    fn process(&self, mode: Option<&String>) -> Result<()> {
        let Restart { name } = self;
        compose(crate::vec_of_strings!["restart", name], mode.unwrap())
    }
}
