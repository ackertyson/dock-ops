use anyhow::Result;
use structopt::StructOpt;

use crate::util::concat;

use crate::subcommands::{docker, docker_capture, Subcommand};

#[derive(StructOpt)]
pub struct Clean {}

impl Subcommand for Clean {
    fn process(&self, _mode: Option<&String>) -> Result<()> {
        if let Ok(containers) = docker_capture(crate::vec_of_strings!["ps", "-f status=exited", "-a", "-q"]) {
            if !containers.is_empty() {
                println!("Containers...");
                let list = String::from_utf8(containers).expect("Could not parse containers");
                docker(concat(crate::vec_of_strings!["rm"], nonempty_names(list)))
                    .expect("Could not clean containers");
            }
        }

        if let Ok(images) = docker_capture(crate::vec_of_strings!["images" ,"-f dangling=true", "-a", "-q"]) {
            if !images.is_empty() {
                println!("Images...");
                let list = String::from_utf8(images).expect("Could not parse images");
                docker(concat(crate::vec_of_strings!["rmi"], nonempty_names(list)))
                    .expect("Could not clean images");
            }
        }

        if let Ok(volumes) = docker_capture(crate::vec_of_strings!["volume", "ls", "-f dangling=true", "-q"]) {
            if !volumes.is_empty() {
                println!("Volumes...");
                let list = String::from_utf8(volumes).expect("Could not parse volumes");
                docker(concat(crate::vec_of_strings!["volume", "rm"], nonempty_names(list)))
                    .expect("Could not clean volumes");
            }
        }

        Ok(())
    }
}

fn nonempty_names(input: String) -> Vec<String> {
    input.split("\n")
        .filter(|x| !x.is_empty())
        .map(|x| String::from(x))
        .collect()
}
