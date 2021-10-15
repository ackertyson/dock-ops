use std::path::{Component, PathBuf};
use std::fs::create_dir_all;
use std::env::current_dir;
use std::collections::HashMap;

use anyhow::Result;
use dirs::home_dir;
use serde::{Deserialize, Serialize};
use serde_yaml::Value;

use crate::fs::{read, write};

#[derive(Serialize, Deserialize)]
pub struct AppConfig {
    pub version: u8,
    pub compose_files: Vec<String>,
    pub aliases: HashMap<String, String>,
}

#[derive(Serialize, Deserialize)]
pub struct ComposeFile {
  pub services: HashMap<String, Value>,
}

pub fn get(filename: &String) -> Result<AppConfig> {
  match read(config_path(filename)?) {
    Ok(raw) => Ok(serde_json::from_str(&raw)?),
    Err(err) => {
      println!("{:?}", err);
      Ok(AppConfig { aliases: HashMap::new(), compose_files: crate::vec_of_strings![], version: 1 })
    },
  }
}

pub fn put(filename: &String, config: AppConfig) -> Result<()> {
  let contents = serde_json::to_string(&config).expect("Could not serialize config");
  let path = config_path(filename).expect("No such path");
  write(&path, contents).expect("No such file");
  println!("Changes saved to {:?}", path.into_os_string().into_string().unwrap());
  Ok(())
}

fn config_path(filename: &String) -> Result<PathBuf> {
  let mut base = home_dir().unwrap().join(".dock-ops");
  match base.exists() {
    true => (),
    false => println!("Directory {:?} does not exist; okay to create? Y/n", base.as_os_str()),
  }
  current_dir().unwrap().components()
    .filter(|x| match x { // turn absolute path into relative by removing root
      Component::RootDir => false,
      _ => true,
    })
    .for_each(|x| base.push(x));
  create_dir_all(&base).expect("Could not create dir");
  base.push(filename);
  Ok(base)
}
