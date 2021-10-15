use anyhow::Result;
use structopt::StructOpt;

use crate::subcommands::compose;

#[derive(StructOpt)]
pub struct Logs {
    pub service: Option<String>
}

pub fn logs(Logs { service }: &Logs) -> Result<()> {
    let mut args = vec!["logs"];
    args.push("-f");
    match service {
        Some(val) => args.push(val),
        None => (),
    }
    compose(args)
}
