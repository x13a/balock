use std::env;
use std::error;
use std::num::ParseIntError;
use std::path::PathBuf;
use std::process::exit;
use std::result;

use sha2::{Digest, Sha256};

const EXIT_SUCCESS: i32 = 0;
const EXIT_USAGE: i32 = 2;

mod flag {
    pub const HELP: &'static str = "h";
    pub const VERSION: &'static str = "V";
}

enum PrintDestination {
    Stdout,
    Stderr,
}

fn print_usage(to: PrintDestination) {
    let usage = format!(
        "{P} [-{h}|{V}] <HEX1> <HEX2>\n\n\
         [-{h}] * Print help and exit\n\
         [-{V}] * Print version and exit",
        P = PathBuf::from(env::args_os().next().unwrap())
            .file_name()
            .unwrap()
            .to_string_lossy(),
        h = flag::HELP,
        V = flag::VERSION,
    );
    match to {
        PrintDestination::Stdout => println!("{}", usage),
        PrintDestination::Stderr => eprintln!("{}", usage),
    }
}

#[derive(Default)]
struct Opts {
    hex1: String,
    hex2: String,
}

fn get_opts() -> Result<Opts> {
    let mut argv = env::args().skip(1);
    if argv.len() == 0 {
        print_usage(PrintDestination::Stderr);
        exit(EXIT_USAGE);
    }
    let mut opts = Opts::default();
    loop {
        let arg = match argv.next() {
            Some(s) => s,
            None => break,
        };
        if !arg.starts_with('-') {
            opts.hex1 = arg;
            opts.hex2 = argv.next().unwrap_or_default();
            break;
        }
        match arg[1..].as_ref() {
            flag::HELP => {
                print_usage(PrintDestination::Stdout);
                exit(EXIT_SUCCESS);
            }
            flag::VERSION => {
                println!("{}", env!("CARGO_PKG_VERSION"));
                exit(EXIT_SUCCESS);
            }
            _ => {}
        }
    }
    if opts.hex1.is_empty() || opts.hex2.is_empty() {
        eprintln!("{}", "invalid hex");
        exit(EXIT_USAGE);
    }
    Ok(opts)
}

type Result<T> = result::Result<T, Box<dyn error::Error>>;

fn decode_hex(s: impl AsRef<str>) -> result::Result<Vec<u8>, ParseIntError> {
    let s = s.as_ref();
    (0..s.len())
        .step_by(2)
        .map(|i| u8::from_str_radix(&s[i..i + 2], 16))
        .collect()
}

fn bruteforce_code(v1: impl AsRef<str>, v2: impl AsRef<str>) -> Result<String> {
    let v1 = v1.as_ref().split_whitespace().collect::<String>();
    let v2 = v2.as_ref().split_whitespace().collect::<String>();
    assert_eq!(v1.len(), v2.len());
    assert_eq!(v1.len(), 64);
    let checksum = decode_hex(&v1)?;
    let mut buf1: [u8; 64] = [0; 64];
    let mut buf2: [u8; 8] = [0; 8];
    buf1[32..].clone_from_slice(&decode_hex(&v2)?);
    for code in (0..=99999999).rev() {
        let mut i: i32 = code;
        for idx in (0..=7).rev() {
            buf2[idx] = (i % 10) as u8 + 48;
            i /= 10;
        }
        buf1[..32].clone_from_slice(&Sha256::digest(&buf2));
        if Sha256::digest(&buf1)[..] == checksum {
            return Ok(format!("{:0>8}", code));
        }
    }
    Err("code not found".into())
}

fn main() -> Result<()> {
    let opts = get_opts()?;
    println!("{}", bruteforce_code(opts.hex1, opts.hex2)?);
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    const V1: &'static str = "E3 EE B0 95 58 C9 6E 6C 45 63 CE 73 91 4C 32 F7 D2 EA 51 54 62 7A DF 3C 4B 86 A4 17 D7 F5 D0 C8";
    const V2: &'static str = "B4 C0 E2 90 95 87 6F F6 05 10 C4 34 C0 1C 4C A4 CE 41 EB 20 57 77 33 EA 87 DC C4 79 E3 CE F5 3C";
    const RESULT: &'static str = "97979686";

    #[test]
    fn bruteforce() {
        assert_eq!(bruteforce_code(V1, V2).unwrap_or_default(), RESULT);
    }
}
