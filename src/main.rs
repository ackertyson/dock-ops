use anyhow::Result;
use structopt::{clap::AppSettings, StructOpt};

use crate::subcommands::all::*;

mod config;
mod fs;
mod subcommands;
mod term;
mod util;

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
        Cmd::Run(args) => run(args),
        Cmd::Setup(_) => setup(),
        Cmd::Up(args) => up(args),
        Cmd::InvokedAlias(args) => invoke_alias(args, &input),
    }
}

#[derive(StructOpt)]
#[structopt(name = "DockOps")]
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
    Attach(Attach),
    #[structopt(about = "docker build . -t ...")]
    Build(Build),
    #[structopt(setting = AppSettings::Hidden, about = "[internal] generate completions")]
    Complete(Complete),
    #[structopt(about = "docker compose config ...")]
    Config(Config),
    #[structopt(about = "docker compose down --remove-orphans ...")]
    Down(Down),
    #[structopt(about = "docker compose exec ...")]
    Exec(Exec),
    #[structopt(about = "docker images ...")]
    Images(Images),
    #[structopt(about = "docker compose logs -f ...")]
    Logs(Logs),
    #[structopt(about = "docker compose ps ...")]
    Ps(Ps),
    #[structopt(about = "docker ps ...")]
    Psa(Psa),
    #[structopt(about = "docker compose restart ...")]
    Restart(Restart),
    #[structopt(about = "docker rmi ...")]
    Rmi(Rmi),
    #[structopt(about = "docker compose run --rm ...")]
    Run(Run),
    #[structopt(about = "[DockOps] update project configuration")]
    Setup(Setup),
    #[structopt(about = "docker compose up ...")]
    Up(Up),
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
