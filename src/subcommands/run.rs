use anyhow::Result;
use structopt::StructOpt;

use crate::subcommands::{compose, Subcommand};
use crate::util::concat;

#[derive(StructOpt)]
pub struct Run {
    #[structopt(subcommand)]
    pub cmd: RunCmd,
}

#[derive(StructOpt)]
pub enum RunCmd {
    #[structopt(external_subcommand)]
    Args(Vec<String>),
}

impl Subcommand for Run {
    fn process(&self, mode: Option<&String>) -> Result<()> {
        let Run { cmd } = self;
        match cmd {
            RunCmd::Args(args) => {
                compose(concat(
                    crate::vec_of_strings!["run", "--rm"],
                    args.iter().map(String::to_owned).collect()),
                        mode.unwrap())
            }
        }
    }
}
