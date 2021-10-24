use anyhow::Result;
use structopt::StructOpt;

use crate::subcommands::{compose, Subcommand};

#[derive(StructOpt)]
pub struct Logs {
    pub service: Option<String>
}

impl Subcommand for Logs {
    fn process(&self, mode: Option<&String>) -> Result<()> {
        let Logs { service } = self;
        let mode = mode.unwrap();
        let mut args = crate::vec_of_strings!["logs"];
        args.push("-f".to_string());
        match service {
            Some(val) => args.push(val.to_string()),
            None => (),
        }
        compose(args, mode)
    }
}
