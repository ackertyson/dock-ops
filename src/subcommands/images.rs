use anyhow::Result;
use structopt::StructOpt;

use crate::subcommands::docker;

#[derive(StructOpt)]
pub struct Images {
    name: Option<String>,
}

pub fn images(Images { name }: &Images) -> Result<()> {
    match name {
        Some(x) => docker(crate::vec_of_strings!["images", x]),
        None => docker(crate::vec_of_strings!["images"])
    }
}
