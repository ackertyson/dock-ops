use std::fs::File;
use std::io::{Write, BufReader};
use std::io::prelude::*;
use std::path::PathBuf;

use anyhow::Result;

pub fn read(filename: PathBuf) -> Result<String> {
    let file = File::open(filename)?;
    let mut buf_reader = BufReader::new(file);
    let mut contents = String::new();
    buf_reader.read_to_string(&mut contents)?;
    //io::stdout().write_all(&contents.as_bytes()).unwrap();
    Ok(contents)
}

pub fn write(filename: &PathBuf, content: String) -> Result<()> {
    let mut file = File::create(filename)?;
    Ok(file.write_all(content.as_bytes())?)
}
