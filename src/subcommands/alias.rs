use anyhow::Result;
use structopt::{clap::AppSettings, StructOpt};

use crate::config::{AppConfig, get, put};

#[derive(StructOpt)]
#[structopt(setting = AppSettings::TrailingVarArg)]
pub struct Alias {
    #[structopt(short, long)]
    pub delete: bool,
    pub name: String,
    #[structopt(conflicts_with("delete"))]
    pub args: Vec<String>,
}

pub fn alias(Alias { name, delete, args }: &Alias) -> Result<()> {
    let AppConfig { mut aliases, compose_files, version } = get(&String::from("development.json"))?;
    match delete {
        true => {
            aliases.remove(&name.to_string());
            let config = AppConfig {
                aliases,
                compose_files,
                version
            };
            put(&String::from("development.json"), config)
        },
        _ => {
            aliases.insert(name.to_string(), args.join(" "));
            let config = AppConfig {
                aliases,
                compose_files,
                version
            };
            put(&String::from("development.json"), config)
        }
    }
}
