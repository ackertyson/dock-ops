use anyhow::Result;
use structopt::StructOpt;

use crate::subcommands::docker;

#[derive(StructOpt)]
pub struct Build {
    #[structopt(help = "image tag")]
    pub tag: String,
}

pub fn build(Build { tag }: &Build) -> Result<()> {
    docker(vec!["build", ".", "-t", tag])
}
