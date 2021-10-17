use std::io::Write;
use std::io::{self, stdin, stdout, BufRead, BufReader, Read};
use std::process::{Command, Stdio};
use std::thread;
use std::time;

use anyhow::Result;
use console::Style;
use termion;
use termion::event::{Event, Key};
use termion::input::TermRead;
use termion::raw::IntoRawMode;

pub fn interactive(command: &str, args: Vec<String>) -> Result<()> {
    let mut child = Command::new(command)
        .args(args)
        .stdout(Stdio::piped())
        .stdin(Stdio::piped())
        .spawn()
        .expect("Command failed");

    {
        let stdin = child.stdin.as_mut().expect("Failed to open stdin");
        stdin.write_all("Hello, world!".as_bytes()).expect("Failed to write to stdin");
    }

    let stdout = stdout();
    let mut stdout = stdout.lock().into_raw_mode().unwrap();
    loop {
        let mut buf = [0; 8];
        let size = stdout.read(&mut buf[..])?;
        stdout.write_all(&buf[..size]).unwrap();
        thread::sleep(time::Duration::from_millis(50));
    }

    Ok(())
}

// use std::io::Write;
// use std::process::{Command, Stdio};
//
// let mut child = Command::new("rev")
//     .stdin(Stdio::piped())
//     .stdout(Stdio::piped())
//     .spawn()
//     .expect("Failed to spawn child process");
//
// {
//     let stdin = child.stdin.as_mut().expect("Failed to open stdin");
//     stdin.write_all("Hello, world!".as_bytes()).expect("Failed to write to stdin");
// }
//
// let output = child.wait_with_output().expect("Failed to read stdout");
// assert_eq!(String::from_utf8_lossy(&output.stdout), "!dlrow ,olleH");


pub fn show_setup(files: Vec<String>) -> Result<Vec<String>> {
    let bling = Style::new().cyan().bold();
    println!("Available YAML files:");
    for (pos, file) in files.iter().enumerate() {
        println!("{}. {}", bling.apply_to(pos + 1), file)
    }
    println!();
    println!("Commands:");
    println!("- [{}, {}, ..., {}] {}", bling.apply_to(1), bling.apply_to(2), bling.apply_to("N"), "Add YAML file");
    println!("- [{}] {}", bling.apply_to("BACKSPACE"), "Remove YAML file");
    println!("- [{}]ancel {}", bling.apply_to("C"), "(exit without saving changes)");
    println!("- [{}] {}", bling.apply_to("ENTER"), "(exit and save changes)");
    println!();
    println!("In {} mode, Docker Compose commands should use:", "DEVELOPMENT");

    term(files)
}

pub fn sys_cmd(command: &str, args: Vec<String>) -> Result<()> {
    // https://rust-lang-nursery.github.io/rust-cookbook/os/external.html#continuously-process-child-process-outputs
    let output = Command::new(command)
        .args(args)
        .stdout(Stdio::piped())
        .stdin(Stdio::piped())
        .spawn()?;

    BufReader::new(output.stdout.expect("Could not pipe to stdout"))
        .lines()
        .filter_map(|line| line.ok())
        .for_each(|line| println!("{}", line));

    Ok(())
}

pub fn sys_cmd_output(command: &str, args: Vec<String>) -> Result<Vec<u8>> {
    let output = Command::new(command)
        .args(args)
        .stdout(Stdio::piped())
        .output()?;
    Ok(output.stdout)
}

fn filelist(files: &Vec<String>) -> String {
    match files.len() {
        0 => "".to_string(),
        _ => {
            format!("-f {}", files.join(" -f "))
        }
    }
}

fn term(files: Vec<String>) -> Result<Vec<String>> { // https://stackoverflow.com/a/55881770
    // Set terminal to raw mode to allow reading stdin one key at a time
    let mut stdout = io::stdout().into_raw_mode().unwrap();
    let stdin = stdin();

    write!(stdout, "{}% docker compose {}", termion::cursor::Hide, filelist(&files)).unwrap();
    stdout.lock().flush().unwrap();
    let mut selected_files = files.clone();

    for c in stdin.events() {
        let evt = c.unwrap();
        match evt {
            Event::Key(Key::Char('c')) => {
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
            Event::Key(Key::Char('1')) => {
                match filename_to_add(&files, &selected_files, 0) {
                    Some(filename) => {
                        selected_files.push(filename);
                        write!(stdout, "\r{}% docker compose {}", termion::clear::CurrentLine, filelist(&selected_files)).unwrap();
                    },
                    None => (),
                }
            },
            Event::Key(Key::Char('2')) => {
                match filename_to_add(&files, &selected_files, 1) {
                    Some(filename) => {
                        selected_files.push(filename);
                        write!(stdout, "\r{}% docker compose {}", termion::clear::CurrentLine, filelist(&selected_files)).unwrap();
                    },
                    None => (),
                }
            },
            Event::Key(Key::Char('3')) => {
                match filename_to_add(&files, &selected_files, 2) {
                    Some(filename) => {
                        selected_files.push(filename);
                        write!(stdout, "\r{}% docker compose {}", termion::clear::CurrentLine, filelist(&selected_files)).unwrap();
                    },
                    None => (),
                }
            },
            _ => (),
        }
        stdout.flush().unwrap();
    }

    write!(stdout, "{}", termion::cursor::Show).unwrap(); // I mean... we have to restore the cursor manually? what??
    Ok(selected_files)
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
