use anyhow::Result;
use structopt::StructOpt;

use crate::subcommands::compose;
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

pub fn exec(Exec { cmd }: &Exec) -> Result<()> {
    match cmd {
        ExecCmd::Args(args) => {
            compose(concat(
                crate::vec_of_strings!["exec"],
                args.iter().map(String::to_owned).collect()))
        }
    }
}
