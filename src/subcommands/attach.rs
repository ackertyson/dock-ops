use anyhow::Result;
use structopt::StructOpt;

use crate::subcommands::{docker, Subcommand};

#[derive(StructOpt)]
pub struct Attach {
    #[structopt(help = "")]
    pub container: String,
}

impl Subcommand for Attach {
    fn process(&self, _mode: Option<&String>) -> Result<()> {
        let Attach { container } = self;
        docker(crate::vec_of_strings!["attach", "--sig-proxy=false", container])
    }
}
