use anyhow::Result;
use structopt::StructOpt;

use crate::subcommands::{docker, Subcommand};

#[derive(StructOpt)]
pub struct Build {
    #[structopt(help = "image tag")]
    pub tag: String,
}

impl Subcommand for Build {
    fn process(&self, _mode: Option<&String>) -> Result<()> {
        let Build { tag } = self;
        docker(crate::vec_of_strings!["build", ".", "-t", tag])
    }
}
