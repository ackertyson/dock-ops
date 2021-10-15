use anyhow::Result;
use structopt::StructOpt;

use crate::subcommands::docker;

#[derive(StructOpt)]
pub struct Attach {
    #[structopt(help = "")]
    pub container: String,
}

pub fn attach(Attach { container }: &Attach) -> Result<()> {
    docker(crate::vec_of_strings!["attach", "--sig-proxy=false", container])
}
