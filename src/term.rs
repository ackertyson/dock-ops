use std::fs::create_dir_all;
use std::io::Write;
use std::io::{self, stdin};
use std::path::PathBuf;
use std::process::Command;

use anyhow::Result;
use console::Style;
use termion;
use termion::event::{Event, Key};
use termion::input::TermRead;
use termion::raw::IntoRawMode;

pub fn color_for_mode(mode: &String) -> Style {
    match mode.as_str() {
        "development" => Style::new().cyan().bold(),
        "production" => Style::new().red().bold(),
        _ => Style::new().green().bold(),
    }
}

pub fn confirm_create_config_dir_ui(base: &PathBuf) -> Result<bool> {
    let mut stdout = io::stdout().into_raw_mode()?;
    let stdin = stdin();

    write!(stdout,
        "{}Directory {} does not exist; okay to create? (Y/n) ",
        termion::cursor::Hide,
        base.as_os_str().to_str().unwrap()
    ).unwrap();
    stdout.lock().flush().unwrap();

    let result = match stdin.events().next().unwrap()? {
        Event::Key(Key::Char('y')) | Event::Key(Key::Char('Y')) | Event::Key(Key::Char('\n')) => {
            create_dir_all(base).expect("Could not create dir");
            true
        },
        _ => false,
    };

    write!(stdout, "\r\n{}", termion::cursor::Show).unwrap();
    Ok(result)
}

pub fn external_spawn(command: &str, args: Vec<String>) -> Result<()> {
    Command::new(command)
        .args(args)
        .spawn()
        .unwrap()
        .wait()?;

    Ok(())
}

pub fn external_output(command: &str, args: Vec<String>) -> Result<Vec<u8>> {
    let output = Command::new(command)
        .args(args)
        .output()?;

    Ok(output.stdout)
}

pub fn show_setup(files: Vec<String>, preselected: Vec<String>, mode: &String) -> Result<Vec<String>> {
    let bling = color_for_mode(mode);
    println!("Available YAML files:");
    for (pos, file) in files.iter().enumerate() {
        println!("{}. {}", bling.apply_to(pos + 1), file)
    }
    println!();
    println!("Commands:");
    println!("- [{}, {}, ..., {}] {}", bling.apply_to(1), bling.apply_to(2), bling.apply_to("N"), "Add YAML file");
    println!("- [{}] {}", bling.apply_to("BACKSPACE"), "Remove YAML file");
    println!("- [{}]ancel or [{}]uit {}", bling.apply_to("C"), bling.apply_to("Q"), "(exit without saving changes)");
    println!("- [{}] {}", bling.apply_to("ENTER"), "(exit and save changes)");
    println!();
    println!("In {} mode, Docker Compose commands should use:", mode.to_uppercase());

    select_files_ui(files, preselected)
}

fn filelist(files: &Vec<String>) -> String {
    match files.len() {
        0 => "".to_string(),
        _ => {
            format!("-f {}", files.join(" -f "))
        }
    }
}

fn filename_to_add(available: &Vec<String>, selected: &Vec<String>, pos: usize) -> Option<String> {
    match available.len().le(&pos) {
        true => None,
        false => {
            let filename = available[pos].to_string();
            match selected.contains(&filename) {
                true => None,
                false => Some(filename)
            }
        }
    }
}

fn select_files_ui(files: Vec<String>, preselected: Vec<String>) -> Result<Vec<String>> {
    // Set terminal to raw mode to allow reading stdin one key at a time
    let mut stdout = io::stdout().into_raw_mode().unwrap();
    let stdin = stdin();

    write!(stdout, "{}% docker compose {}", termion::cursor::Hide, filelist(&preselected)).unwrap();
    stdout.lock().flush().unwrap();
    let mut selected_files = preselected.clone();

    for c in stdin.events() {
        match c.unwrap() {
            Event::Key(Key::Char('c')) | Event::Key(Key::Char('q')) | Event::Key(Key::Ctrl('c')) | Event::Key(Key::Esc) => {
                selected_files.clear();
                write!(stdout, "\r\n").unwrap();
                break;
            },
            Event::Key(Key::Char('\n')) => {
                write!(stdout, "\r\n").unwrap();
                break;
            },
            Event::Key(Key::Backspace) => {
                selected_files.pop();
                write!(stdout, "\r{}% docker compose {}", termion::clear::CurrentLine, filelist(&selected_files)).unwrap();
            },
            Event::Key(Key::Char(n)) => {
                match char::to_digit(n, 10) {
                    Some(x) => { // numeric char inputs
                        if let Some(filename) = filename_to_add(&files, &selected_files, (x as usize) - 1) {
                            selected_files.push(filename);
                            write!(stdout, "\r{}% docker compose {}", termion::clear::CurrentLine, filelist(&selected_files)).unwrap();
                        }
                    },
                    None => ()
                }
            },
            _ => (),
        }
        stdout.flush().unwrap();
    }

    write!(stdout, "{}", termion::cursor::Show).unwrap(); // I mean... we have to restore the cursor manually? what??
    Ok(selected_files)
}
