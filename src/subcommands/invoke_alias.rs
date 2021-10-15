use anyhow::Result;

use crate::config::{AppConfig, get};
use crate::opts::Dock;
use crate::subcommands::sys_cmd;

pub fn invoke_alias(args: &Vec<String>, Dock { reinvoked, .. }: &Dock) -> Result<()> {
    match reinvoked {
        true => panic!("Bailing on looped alias invocation"),
        false => {
            let name = args.get(0).unwrap();
            let AppConfig { aliases,  .. } = get(&String::from("development.json"))?;
            match aliases.get(name) {
                Some(command) => {
                    let mut reinvoked_args = vec!["-r"];
                    reinvoked_args.append(&mut command.split(" ").collect());
                    sys_cmd("dock", reinvoked_args)
                },
                None => { // any unmatched subcommand will land here (because of structopt "external_subcommand" annotation)
                    println!("[ERROR] Unknown command '{}'", name);
                    println!();
                    sys_cmd("dock", vec!["-r", "help"])
                },
            }
        }
    }
}
