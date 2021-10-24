use anyhow::Result;
use structopt::StructOpt;

use crate::subcommands::{compose, Subcommand};

#[derive(StructOpt)]
pub struct Ps {}

impl Subcommand for Ps {
    fn process(&self, mode: Option<&String>) -> Result<()> {
        compose(crate::vec_of_strings!["ps"], mode.unwrap())
    }
}
