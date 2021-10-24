use anyhow::Result;
use structopt::StructOpt;

use crate::subcommands::{compose, Subcommand};

#[derive(StructOpt)]
pub struct Down {}

impl Subcommand for Down {
    fn process(&self, mode: Option<&String>) -> Result<()> {
        compose(crate::vec_of_strings!["down", "--remove-orphans"], mode.unwrap())
    }
}
