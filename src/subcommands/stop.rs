use anyhow::Result;
use structopt::StructOpt;

use crate::subcommands::{compose, Subcommand};

#[derive(StructOpt)]
pub struct Stop {
    pub service: Option<String>
}

impl Subcommand for Stop {
    fn process(&self, mode: Option<&String>) -> Result<()> {
        let Stop { service } = self;
        let mode = mode.unwrap();
        let mut args = crate::vec_of_strings!["stop"];
        match service {
            Some(val) => args.push(val.to_string()),
            None => (),
        }
        compose(args, mode)
    }
}
