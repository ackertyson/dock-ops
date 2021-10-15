use anyhow::Result;
use structopt::StructOpt;

use crate::subcommands::compose;
use crate::util::concat;

#[derive(StructOpt)]
pub struct Run {
    pub service: String,
    pub args: Vec<String>,
}

pub fn run(Run { service, args }: &Run) -> Result<()> {
    compose(concat(crate::vec_of_strings!["run", "--rm", service], args.to_owned()))
}
