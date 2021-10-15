use anyhow::Result;
use structopt::StructOpt;

use crate::opts::{Dock, Cmd};
use crate::subcommands::all::*;

mod config;
mod fs;
mod opts;
mod subcommands;
mod term;

fn main() -> Result<()> {
    let input = Dock::from_args();
    match &input.cmd {
        Cmd::Alias(args) => alias(args),
        Cmd::Aliases(_) => aliases(),
        Cmd::Attach(args) => attach(args),
        Cmd::Build(args) => build(args),
        Cmd::Complete(args) => complete(args),
        Cmd::Config(_) => config(),
        Cmd::Down(_) => down(),
        Cmd::Exec(args) => exec(args),
        Cmd::Images(_) => images(),
        Cmd::Logs(args) => logs(args),
        Cmd::Ps(args) => ps(args),
        Cmd::Psa(_) => psa(),
        Cmd::Restart(args) => restart(args),
        Cmd::Rmi(args) => rmi(args),
        Cmd::Setup(_) => setup(),
        Cmd::Up(args) => up(args),
        Cmd::InvokedAlias(args) => invoke_alias(args, &input),
    }
}
