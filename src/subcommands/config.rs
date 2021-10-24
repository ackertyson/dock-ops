use anyhow::Result;
use structopt::StructOpt;

use crate::subcommands::{compose, Subcommand};

#[derive(StructOpt)]
pub struct Config {}

impl Subcommand for Config {
    fn process(&self, mode: Option<&String>) -> Result<()> {
        compose(crate::vec_of_strings!["config"], mode.unwrap())
    }
}
