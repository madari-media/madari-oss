use log::{info, warn};
use rinf::debug_print;

mod messages;
mod torrent_server;

// use tokio_with_wasm::alias as tokio; // web

rinf::write_interface!();

#[tokio::main(flavor = "current_thread")]
async fn main() {
    tokio::spawn(torrent_server::communicate());

    debug_print!("Hello world");

    rinf::dart_shutdown().await;
}
