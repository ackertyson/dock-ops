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
    let mut args = crate::vec_of_strings!["up"];
    match detached {
        true => args.push("-d".to_string()),
        false => (),
    }
    match service {
        Some(val) => args.push(val.to_string()),
        None => (),
    }
    compose(args)
}
