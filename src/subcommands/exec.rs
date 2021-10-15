use anyhow::Result;
use structopt::StructOpt;

use crate::subcommands::compose;

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
            let mut exec_args = vec!["exec"];
            exec_args.append(&mut args.iter().map(AsRef::as_ref).collect());
            compose(exec_args)
        }
    }
}
