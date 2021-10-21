use anyhow::Result;
use structopt::StructOpt;

use crate::subcommands::docker_tty;
use crate::util::concat;

#[derive(StructOpt)]
pub struct Run {
    pub service: String,
    pub args: Vec<String>,
}

pub fn run(Run { service, args }: &Run) -> Result<()> {
    docker_tty(concat(crate::vec_of_strings!["run", "--rm", service], args.to_owned()))
}
