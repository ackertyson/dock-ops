use anyhow::Result;

use crate::config::{AppConfig, get};
use crate::subcommands::external_spawn;
use crate::util::*;

pub fn invoke_alias(args: &Vec<String>, reinvoked: bool, mode: String) -> Result<()> {
    match reinvoked {
        true => panic!("Bailing on looped alias invocation"),
        false => {
            let name = args.get(0).unwrap();
            let AppConfig { aliases,  .. } = get(&mode)?;
            match aliases.get(name) {
                Some(command) => {
                    external_spawn("dock", concat(
                        crate::vec_of_strings!["-r"],
                        command.split(' ').map(String::from).collect()))
                },
                None => { // any unmatched subcommand will land here (because of structopt "external_subcommand" annotation)
                    println!("[ERROR] Unknown command '{}'", name);
                    println!();
                    external_spawn("dock", crate::vec_of_strings!["-r", "help"])
                },
            }
        }
    }
}
