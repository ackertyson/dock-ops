use anyhow::Result;
use structopt::StructOpt;

use crate::subcommands::compose;

#[derive(StructOpt)]
pub struct Up {
    #[structopt(short, help = "Background (detached)")]
    pub detached: bool,
    pub service: Option<String>,
}

pub fn up(Up { detached, service }: &Up) -> Result<()> {
    let mut args = vec!["up"];
    match detached {
        true => args.push("-d"),
        false => (),
    }
    match service {
        Some(val) => args.push(val),
        None => (),
    }
    compose(args)
}
