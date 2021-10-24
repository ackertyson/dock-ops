use anyhow::Result;
use structopt::StructOpt;

use crate::subcommands::{compose, Subcommand};

#[derive(StructOpt)]
pub struct Up {
    #[structopt(short, help = "Background (detached)")]
    pub detached: bool,
    pub service: Option<String>,
}

impl Subcommand for Up {
    fn process(&self, mode: Option<&String>) -> Result<()> {
        let Up { detached, service } = self;
        let mode = mode.unwrap();
        let mut args = crate::vec_of_strings!["up"];
        match detached {
            true => args.push("-d".to_string()),
            false => (),
        }
        match service {
            Some(val) => args.push(val.to_string()),
            None => (),
        }
        compose(args, mode)
    }
}
