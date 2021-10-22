use anyhow::Result;

use crate::config::{AppConfig, get};
use crate::Dock;
use crate::subcommands::sys_cmd;
use crate::util::*;

pub fn invoke_alias(args: &Vec<String>, Dock { reinvoked, .. }: &Dock) -> Result<()> {
    match reinvoked {
        true => panic!("Bailing on looped alias invocation"),
        false => {
            let name = args.get(0).unwrap();
            let AppConfig { aliases,  .. } = get(&String::from("development.json"))?;
            match aliases.get(name) {
                Some(command) => {
                    sys_cmd("dock", concat(
                        crate::vec_of_strings!["-r"],
                        command.split(' ').map(String::from).collect()))
                },
                None => { // any unmatched subcommand will land here (because of structopt "external_subcommand" annotation)
                    println!("[ERROR] Unknown command '{}'", name);
                    println!();
                    sys_cmd("dock", crate::vec_of_strings!["-r", "help"])
                },
            }
        }
    }
}
