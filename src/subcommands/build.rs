use anyhow::Result;
use structopt::StructOpt;

use crate::subcommands::docker;

#[derive(StructOpt)]
pub struct Build {
    #[structopt(help = "image tag")]
    pub tag: String,
}

pub fn build(Build { tag }: &Build) -> Result<()> {
    docker(crate::vec_of_strings!["build", ".", "-t", tag])
}
