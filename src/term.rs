use std::io;
use std::io::Write;
use std::thread;
use std::time;

use anyhow::Result;
use console::Style;
use termion;
use termion::input::TermRead;
use termion::raw::IntoRawMode;

fn filelist(files: &Vec<String>) -> String {
    match files.len() {
        0 => "".to_string(),
        _ => {
            format!("-f {}", files.join(" -f "))
        }
    }
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
    term(files)
}

fn term(files: Vec<String>) -> Result<Vec<String>> { // https://stackoverflow.com/a/55881770
    // Set terminal to raw mode to allow reading stdin one key at a time
    let mut stdout = io::stdout().into_raw_mode().unwrap();
    let mut stdin = termion::async_stdin().keys();

    write!(stdout, "{}% docker compose {}", termion::cursor::Hide, filelist(&files)).unwrap();
    stdout.lock().flush().unwrap();
    let mut selected_files = files.clone();

    loop {
        let input = stdin.next();

        if let Some(Ok(key)) = input {
            match key {
                termion::event::Key::Char('c') => {
                    selected_files.clear();
                    write!(stdout, "\r\n").unwrap();
                    break;
                }
                termion::event::Key::Char('\n') => {
                    write!(stdout, "\r\n").unwrap();
                    break;
                }
                termion::event::Key::Backspace => {
                    selected_files.pop();
                    write!(stdout, "\r{}% docker compose {}", termion::clear::CurrentLine, filelist(&selected_files)).unwrap();
                    stdout.lock().flush().unwrap();
                }
                termion::event::Key::Char('1') => {
                    match filename_to_add(&files,&selected_files, 0) {
                        Some(filename) => {
                            selected_files.push(filename);
                            write!(stdout, "\r{}% docker compose {}", termion::clear::CurrentLine, filelist(&selected_files)).unwrap();
                            stdout.lock().flush().unwrap();
                        },
                        None => (),
                    }
                }
                termion::event::Key::Char('2') => {
                    match filename_to_add(&files, &selected_files, 1) {
                        Some(filename) => {
                            selected_files.push(filename);
                            write!(stdout, "\r{}% docker compose {}", termion::clear::CurrentLine, filelist(&selected_files)).unwrap();
                            stdout.lock().flush().unwrap();
                        }
                        None => (),
                    }
                }
                termion::event::Key::Char('3') => {
                    match filename_to_add(&files,&selected_files, 2) {
                        Some(filename) => {
                            selected_files.push(filename);
                            write!(stdout, "\r{}% docker compose {}", termion::clear::CurrentLine, filelist(&selected_files)).unwrap();
                            stdout.lock().flush().unwrap();
                        }
                        None => (),
                    }
                }
                _ => {}
            }
        }
        thread::sleep(time::Duration::from_millis(50));
    }

    write!(stdout, "{}", termion::cursor::Show).unwrap(); // I mean... we have to restore the cursor manually? what??
    Ok(selected_files)
}

fn filename_to_add(available: &Vec<String>, selected: &Vec<String>, pos: usize) -> Option<String> {
    match available.len().lt(&pos) {
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
