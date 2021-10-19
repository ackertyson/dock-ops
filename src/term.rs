use std::io::{Read, Write};
use std::io::{self, stdin, stdout, BufRead, BufReader};
use std::process::{Command, Stdio};
use std::thread;

use anyhow::Result;
use console::Style;
use termion;
use termion::event::{Event, Key};
use termion::input::TermRead;
use termion::raw::IntoRawMode;

pub fn interactive(command: &str, args: Vec<String>) -> Result<()> {
    let stdin = stdin();
    let mut stdout = stdout();

    let child = Command::new(command)
        .args(args)
        .stdin(Stdio::piped())
        .stdout(Stdio::piped())
        .stderr(Stdio::inherit())
        .spawn()?;

    let mut buf = [0; 8];
    let mut child_stdout_buffer = BufReader::new(child.stdout.unwrap());
    let mut child_stdin = child.stdin.unwrap();

    let handle = thread::spawn(move || {
        for c in stdin.events() {
            let evt = c.unwrap();
            match evt {
                Event::Key(Key::Ctrl('d')) | Event::Key(Key::Ctrl('c')) => {
                    break;
                },
                Event::Key(Key::Char(char)) => {
                    // write!(child.stdin.unwrap(), "{}", "\\dt").unwrap();
                    match child_stdin.write_all(char.to_string().as_bytes()) {
                        Ok(_) => (),
                        Err(e) => eprintln!("{:?}", e),
                    }
                },
                _ => (),
            }
        }
    });

    loop {
        let n = child_stdout_buffer.read(&mut buf[..]).unwrap();
        if n == 0 {
            break;
        }

        stdout.write(&buf[..n]).unwrap();
        // stdout.flush().unwrap();
    }

    handle.join().unwrap();
    Ok(())
}

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

    select_files_ui(files)
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

fn select_files_ui(files: Vec<String>) -> Result<Vec<String>> {
    // Set terminal to raw mode to allow reading stdin one key at a time
    let mut stdout = io::stdout().into_raw_mode().unwrap();
    let stdin = stdin();

    write!(stdout, "{}% docker compose {}", termion::cursor::Hide, filelist(&files)).unwrap();
    stdout.lock().flush().unwrap();
    let mut selected_files = files.clone();

    for c in stdin.events() {
        let evt = c.unwrap();
        match evt {
            Event::Key(Key::Char('c')) | Event::Key(Key::Ctrl('c')) | Event::Key(Key::Esc) => {
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
