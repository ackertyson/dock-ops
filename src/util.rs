pub fn concat(a: Vec<String>, b: Vec<String>) -> Vec<String> {
    let mut c = a.clone();
    c.append(&mut b.clone());
    c
}
