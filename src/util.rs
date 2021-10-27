pub fn concat(a: Vec<String>, b: Vec<String>) -> Vec<String> {
    let mut c = a.clone();
    c.append(&mut b.clone());
    c
}

pub fn mode_from(production: bool, mode: Option<String>) -> String {
    match production {
        true => "production".to_string(),
        _ => mode.or(Some("development".to_string())).unwrap(),
    }
}
