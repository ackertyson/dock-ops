use anyhow::Result;
use structopt::StructOpt;

use crate::subcommands::compose;

#[derive(StructOpt)]
pub struct Logs {
    pub service: Option<String>
}

pub fn logs(Logs { service }: &Logs, mode: &String) -> Result<()> {
    let mut args = crate::vec_of_strings!["logs"];
    args.push("-f".to_string());
    match service {
        Some(val) => args.push(val.to_string()),
        None => (),
    }
    compose(args, mode)
}
