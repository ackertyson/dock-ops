use anyhow::Result;
use structopt::{clap::AppSettings, StructOpt};

use crate::subcommands::all::*;
use crate::util::mode_from;

mod config;
mod fs;
mod subcommands;
mod term;
mod util;

fn main() -> Result<()> {
    let Dock { cmd, mode, production, reinvoked } = Dock::from_args();
    let mode = mode_from(production, mode);

    match &cmd {
        Cmd::Alias(alias) => alias.process(mode),
        Cmd::Aliases(aliases) => aliases.process(mode),
        Cmd::Attach(passthru) => passthru.docker(vec_of_strings!["attach", "--sig-proxy=false"]),
        Cmd::Build(passthru) => passthru.compose(vec_of_strings!["build"], mode),
        Cmd::Clean(passthru) => passthru.docker(vec_of_strings!["system", "prune", "-f", "--volumes"]),
        Cmd::Complete(complete) => complete.process(),
        Cmd::Config(passthru) => passthru.compose(vec_of_strings!["config"], mode),
        Cmd::Dbuild(passthru) => passthru.docker(vec_of_strings!["build", ".", "-t"]),
        Cmd::Down(passthru) => passthru.compose(vec_of_strings!["down", "--remove-orphans"], mode),
        Cmd::Exec(passthru) => passthru.compose(vec_of_strings!["exec"], mode),
        Cmd::Images(passthru) => passthru.docker(vec_of_strings!["images"]),
        Cmd::Logs(passthru) => passthru.compose(vec_of_strings!["logs", "-f"], mode),
        Cmd::Ps(passthru) => passthru.compose(vec_of_strings!["ps"], mode),
        Cmd::Psa(passthru) => passthru.docker(vec_of_strings!["ps"]),
        Cmd::Restart(passthru) => passthru.compose(vec_of_strings!["restart"], mode),
        Cmd::Rmi(passthru) => passthru.docker(vec_of_strings!["rmi"]),
        Cmd::Run(passthru) => passthru.compose(vec_of_strings!["run", "--rm"], mode),
        Cmd::Setup(setup) => setup.process(mode),
        Cmd::Stop(passthru) => passthru.compose(vec_of_strings!["stop"], mode),
        Cmd::Up(passthru) => passthru.compose(vec_of_strings!["up"], mode),
        Cmd::InvokedAlias(args) => invoke_alias(args, reinvoked, mode),
    }
}

#[derive(StructOpt)]
#[structopt(name = "DockOps", about = "See full docs at https://github.com/ackertyson/dock-ops")]
pub struct Dock {
    #[structopt(short, long, help = "Arbitrary MODE")]
    pub mode: Option<String>,

    #[structopt(short, long, help = "Production MODE")]
    pub production: bool,

    #[structopt(short, long, hidden = true, about = "[internal] to prevent infinitely looped alias invocation")]
    pub reinvoked: bool,

    #[structopt(subcommand)]
    pub cmd: Cmd,
}

#[derive(StructOpt)]
pub enum Cmd {
    #[structopt(about = "[DockOps] create/destroy command alias")]
    Alias(Alias),

    #[structopt(about = "[DockOps] list command aliases")]
    Aliases(Aliases),

    #[structopt(about = "docker attach --sig-proxy=false ...")]
    Attach(Passthru),

    #[structopt(about = "docker compose build ...")]
    Build(Passthru),

    #[structopt(about = "docker system prune -f --volumes")]
    Clean(Passthru),

    #[structopt(setting = AppSettings::Hidden, about = "[internal] generate completions")]
    Complete(Complete),

    #[structopt(about = "docker compose config ...")]
    Config(Passthru),

    #[structopt(about = "docker build . -t ...")]
    Dbuild(Passthru),

    #[structopt(about = "docker compose down --remove-orphans ...")]
    Down(Passthru),

    #[structopt(about = "docker compose exec ...")]
    Exec(Passthru),

    #[structopt(about = "docker images ...")]
    Images(Passthru),

    #[structopt(about = "docker compose logs -f ...")]
    Logs(Passthru),

    #[structopt(about = "docker compose ps ...")]
    Ps(Passthru),

    #[structopt(about = "docker ps ...")]
    Psa(Passthru),

    #[structopt(about = "docker compose restart ...")]
    Restart(Passthru),

    #[structopt(about = "docker rmi ...")]
    Rmi(Passthru),

    #[structopt(about = "docker compose run --rm ...")]
    Run(Passthru),

    #[structopt(about = "[DockOps] update project configuration")]
    Setup(Setup),

    #[structopt(about = "docker compose stop ...")]
    Stop(Passthru),

    #[structopt(about = "docker compose up ...")]
    Up(Passthru),

    #[structopt(external_subcommand)]
    InvokedAlias(Vec<String>),
}

#[macro_export]
macro_rules! vec_of_strings { // https://stackoverflow.com/a/45145246
    // match a list of expressions separated by comma:
    ($($str:expr),*) => ({
        // create a Vec with this list of expressions,
        // calling String::from on each:
        vec![$(String::from($str),)*] as Vec<String>
    });
}
