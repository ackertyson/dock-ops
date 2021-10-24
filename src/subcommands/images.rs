use anyhow::Result;
use structopt::StructOpt;

use crate::subcommands::{docker, Subcommand};

#[derive(StructOpt)]
pub struct Images {
    name: Option<String>,
}

impl Subcommand for Images {
    fn process(&self, _mode: Option<&String>) -> Result<()> {
        let Images { name } = self;
        match name {
            Some(x) => docker(crate::vec_of_strings!["images", x]),
            None => docker(crate::vec_of_strings!["images"])
        }
    }
}
