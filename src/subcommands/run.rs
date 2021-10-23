use anyhow::Result;
use structopt::StructOpt;

use crate::subcommands::compose;
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

pub fn run(Run { cmd }: &Run) -> Result<()> {
    match cmd {
        RunCmd::Args(args) => {
            compose(concat(
                crate::vec_of_strings!["run", "--rm"],
                args.iter().map(String::to_owned).collect()))
        }
    }
}
