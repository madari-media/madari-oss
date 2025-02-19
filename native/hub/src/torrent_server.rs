use crate::messages::*;
use messages::prelude::*;
use rinf::debug_print;

struct StartServer;
struct StopServer;

struct TorrentServer {
    state: ServerStatus,
}

impl Actor for TorrentServer {}

#[async_trait]
impl Handler<StartServer> for TorrentServer {
    type Result = Result<(), String>;

    async fn handle(&mut self, _: StartServer, ctx: &Context<Self>) -> Self::Result {
        self.handle_start().await
    }
}

#[async_trait]
impl Handler<StopServer> for TorrentServer {
    type Result = Result<(), String>;

    async fn handle(&mut self, _: StopServer, ctx: &Context<Self>) -> Self::Result {
        self.handle_stop().await
    }
}

impl TorrentServer {
    pub fn new() -> Self {
        Self {
            state: ServerStatus::Stop,
        }
    }

    pub fn start() -> Address<Self> {
        let context = Context::new();
        let actor = Self::new();
        let addr = context.address();
        tokio::spawn(context.run(actor));
        addr
    }

    async fn handle_start(&mut self) -> Result<(), String> {
        match self.state {
            ServerStatus::Active => {
                debug_print!("Server already active");
                Ok(())
            }
            ServerStatus::Stop => {
                self.start_server().await?;
                self.state = ServerStatus::Active;
                debug_print!("Server activated");
                Ok(())
            }
        }
    }

    async fn handle_stop(&mut self) -> Result<(), String> {
        match self.state {
            ServerStatus::Stop => {
                debug_print!("Server already stopped");
                Ok(())
            }
            ServerStatus::Active => {
                self.stop_server().await?;
                self.state = ServerStatus::Stop;
                debug_print!("Server deactivated");
                Ok(())
            }
        }
    }

    async fn start_server(&mut self) -> Result<(), String> {
        ServerEngine { status: 0, port: 1212 }.send_signal_to_dart();
        debug_print!("started server");
        Ok(())
    }

    async fn stop_server(&mut self) -> Result<(), String> {
        ServerEngine { status: 1, port: 1212 }.send_signal_to_dart();
        debug_print!("stopped server");
        Ok(())
    }
}

pub async fn communicate() {
    let receiver = ServerAction::get_dart_signal_receiver();
    let mut server = TorrentServer::start();

    while let Some(dart_signal) = receiver.recv().await {
        let message: ServerAction = dart_signal.message;

        let status = ServerStatus::try_from(message.status);

        match status.unwrap() {
            ServerStatus::Active => {
                if let Err(e) = server.send(StartServer).await {
                    debug_print!("Failed to start server: {}", e);
                }
            }
            ServerStatus::Stop => {
                if let Err(e) = server.send(StopServer).await {
                    debug_print!("Failed to stop server: {}", e);
                }
            }
        }
    }
}
