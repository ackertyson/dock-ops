use anyhow::Result;
use structopt::StructOpt;

use crate::subcommands::{compose, Subcommand};
use crate::util::concat;

#[derive(StructOpt)]
pub struct Exec {
    #[structopt(subcommand)]
    pub cmd: ExecCmd,
}

#[derive(StructOpt)]
pub enum ExecCmd {
    #[structopt(external_subcommand)]
    Args(Vec<String>),
}

impl Subcommand for Exec {
    fn process(&self, mode: Option<&String>) -> Result<()> {
        let Exec { cmd } = self;
        match cmd {
            ExecCmd::Args(args) => {
                compose(concat(
                    crate::vec_of_strings!["exec"],
                    args.iter().map(String::to_owned).collect()),
                        mode.unwrap())
            }
        }
    }
}
