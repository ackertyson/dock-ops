use anyhow::Result;
use structopt::{clap::AppSettings, StructOpt};

use crate::config::configured_yamls;
use crate::term::external_spawn;
use crate::util::*;

#[derive(StructOpt)]
#[structopt(setting = AppSettings::AllowLeadingHyphen)]
pub struct Passthru {
    pub user_args: Vec<String>,
}

// TODO allow aliases to supercede built-ins of same name
impl Passthru {
    pub fn compose(&self, system_args: Vec<String>, mode: String) -> Result<()> {
        let Passthru { user_args } = self;

        compose(concat(system_args, user_args.clone()), mode)
    }

    pub fn docker(&self, system_args: Vec<String>) -> Result<()> {
        let Passthru { user_args } = self;

        docker(concat(system_args, user_args.clone()))
    }
}

fn compose(args: Vec<String>, mode: String) -> Result<()> {
    docker(concat(
        crate::vec_of_strings!["compose"],
        concat(
            configured_yamls(mode).iter()
                .map(|file| crate::vec_of_strings!["-f", file])
                .flatten()
                .collect(),
            args)))
}

fn docker(args: Vec<String>) -> Result<()> {
    external_spawn("docker", args)
}
