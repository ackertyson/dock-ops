use anyhow::Result;
use structopt::StructOpt;

use crate::subcommands::{compose, Subcommand};

#[derive(StructOpt)]
pub struct Up {
    #[structopt(short, long, help = "")]
    pub detach: bool,
    #[structopt(short, long, help = "")]
    pub force_recreate: bool,
    pub service: Option<String>,
}

impl Subcommand for Up {
    fn process(&self, mode: Option<&String>) -> Result<()> {
        let Up { detach, force_recreate, service } = self;
        let mode = mode.unwrap();
        let mut args = crate::vec_of_strings!["up"];
        match detach {
            true => args.push("-d".to_string()),
            false => (),
        }
        match force_recreate {
            true => args.push("--force-recreate".to_string()),
            false => (),
        }
        match service {
            Some(val) => args.push(val.to_string()),
            None => (),
        }
        compose(args, mode)
    }
}
