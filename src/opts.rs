use structopt::{clap::AppSettings, StructOpt};

use crate::subcommands::all::*;

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
    #[structopt(about = "[DockOps] create command alias")]
    Alias(Alias),
    #[structopt(about = "[DockOps] list command aliases")]
    Aliases(Aliases),
    #[structopt(about = "docker attach --sig-proxy=false ...")]
    Attach(Attach),
    #[structopt(about = "docker build . -t ...")]
    Build(Build),
    #[structopt(setting = AppSettings::Hidden, about = "[internal] generate completions")]
    Complete(Complete),
    #[structopt(about = "docker compose config")]
    Config(Config),
    #[structopt(about = "docker compose down --remove-orphans")]
    Down(Down),
    #[structopt(about = "docker compose exec ...")]
    Exec(Exec),
    #[structopt(about = "docker images")]
    Images(Images),
    #[structopt(about = "docker compose logs -f ...")]
    Logs(Logs),
    #[structopt(about = "docker compose ps")]
    Ps(Ps),
    #[structopt(about = "docker ps")]
    Psa(Psa),
    #[structopt(about = "docker rmi ...")]
    Rmi(Rmi),
    #[structopt(about = "[DockOps] update project configuration")]
    Setup(Setup),
    #[structopt(about = "docker compose up ...")]
    Up(Up),
    #[structopt(external_subcommand)]
    InvokedAlias(Vec<String>),
}
