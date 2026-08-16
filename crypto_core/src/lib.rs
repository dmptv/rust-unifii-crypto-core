uniffi::setup_scaffolding!();

#[uniffi::export]
pub fn greet(name: String) -> String {
    format!("Hello, {name}! This came from Rust.")
}

#[derive(Debug, Clone, uniffi::Record)]
pub struct PriceInfo {
    pub coin_id: String,
    pub usd_price: f64,
}

#[derive(Debug, thiserror::Error, uniffi::Error)]
pub enum PriceError {
    #[error("rate limited by CoinGecko, try again in a bit")]
    RateLimited,

    #[error("network request failed: {reason}")]
    Network { reason: String },

    #[error("unexpected response from CoinGecko: {reason}")]
    InvalidResponse { reason: String },

    #[error("invalid input: {reason}")]
    InvalidInput { reason: String },
}

// Security note: the Swift caller is not a trusted environment — a jailbroken
// device or a Frida-attached process can call any exported function directly
// with arbitrary arguments, bypassing whatever validation the Swift UI layer
// normally does. Every UniFFI-exported function must therefore validate its
// own inputs, the same way a server validates a request body: never assume
// the FFI caller already checked anything.
fn validate_identifier(value: &str) -> Result<(), PriceError> {
    let is_valid = !value.is_empty()
        && value.len() <= 64
        && value
            .chars()
            .all(|c| c.is_ascii_alphanumeric() || c == '-');

    if is_valid {
        Ok(())
    } else {
        Err(PriceError::InvalidInput {
            reason: format!("'{value}' is not a valid identifier"),
        })
    }
}

#[uniffi::export]
pub fn get_price(coin_id: String) -> Result<PriceInfo, PriceError> {
    validate_identifier(&coin_id)?;

    let url = format!(
        "https://api.coingecko.com/api/v3/simple/price?ids={coin_id}&vs_currencies=usd"
    );

    let response = ureq::get(&url).call().map_err(|err| match err {
        ureq::Error::Status(429, _) => PriceError::RateLimited,
        ureq::Error::Status(code, _) => PriceError::Network {
            reason: format!("HTTP {code}"),
        },
        ureq::Error::Transport(transport) => PriceError::Network {
            reason: transport.to_string(),
        },
    })?;

    let body: serde_json::Value = response
        .into_json()
        .map_err(|err| PriceError::InvalidResponse {
            reason: err.to_string(),
        })?;

    let usd_price = body[&coin_id]["usd"]
        .as_f64()
        .ok_or_else(|| PriceError::InvalidResponse {
            reason: format!("no usd price found for '{coin_id}'"),
        })?;

    Ok(PriceInfo { coin_id, usd_price })
}

// --- Async: same lookup as get_price, but as a real Rust `async fn`,
// exported to Swift as a native `async`/`await` function (no manual
// thread-hopping needed on the Swift side, unlike the sync get_price).

static ASYNC_RUNTIME: std::sync::LazyLock<tokio::runtime::Runtime> =
    std::sync::LazyLock::new(|| {
        tokio::runtime::Runtime::new().expect("failed to create tokio runtime")
    });

#[uniffi::export]
pub async fn get_price_async(coin_id: String) -> Result<PriceInfo, PriceError> {
    ASYNC_RUNTIME
        .spawn_blocking(move || get_price(coin_id))
        .await
        .expect("blocking task panicked")
}

// --- Live streaming via Binance WebSocket ---

#[uniffi::export(with_foreign)]
pub trait TickerListener: Send + Sync {
    fn on_update(&self, ticker: PriceInfo);
    fn on_error(&self, message: String);
}

#[derive(uniffi::Object)]
pub struct PriceTicker {
    stop_flag: std::sync::Arc<std::sync::atomic::AtomicBool>,
}

#[uniffi::export]
impl PriceTicker {
    #[uniffi::constructor]
    pub fn new(
        symbols: Vec<String>,
        listener: std::sync::Arc<dyn TickerListener>,
    ) -> Result<std::sync::Arc<Self>, PriceError> {
        for symbol in &symbols {
            validate_identifier(symbol)?;
        }

        let stop_flag = std::sync::Arc::new(std::sync::atomic::AtomicBool::new(false));
        let thread_stop_flag = stop_flag.clone();

        std::thread::spawn(move || {
            let streams: Vec<String> = symbols
                .iter()
                .map(|s| format!("{}@trade", s.to_lowercase()))
                .collect();
            let url = format!(
                "wss://stream.binance.com:9443/stream?streams={}",
                streams.join("/")
            );

            let connection = tungstenite::connect(&url);
            let mut socket = match connection {
                Ok((socket, _response)) => socket,
                Err(err) => {
                    listener.on_error(format!("connection failed: {err}"));
                    return;
                }
            };

            loop {
                if thread_stop_flag.load(std::sync::atomic::Ordering::Relaxed) {
                    break;
                }

                match socket.read() {
                    Ok(tungstenite::Message::Text(text)) => {
                        if let Some(info) = parse_binance_trade(&text) {
                            listener.on_update(info);
                        }
                    }
                    Ok(_) => {}
                    Err(err) => {
                        listener.on_error(format!("socket read error: {err}"));
                        break;
                    }
                }
            }
        });

        Ok(std::sync::Arc::new(Self { stop_flag }))
    }

    pub fn stop(&self) {
        self.stop_flag
            .store(true, std::sync::atomic::Ordering::Relaxed);
    }
}

fn parse_binance_trade(text: &str) -> Option<PriceInfo> {
    let value: serde_json::Value = serde_json::from_str(text).ok()?;
    let data = &value["data"];
    let symbol = data["s"].as_str()?.to_string();
    let price: f64 = data["p"].as_str()?.parse().ok()?;
    Some(PriceInfo {
        coin_id: symbol,
        usd_price: price,
    })
}

// --- gRPC: Rust core as a gRPC *client* to a real external gRPC service
// (Buf's public Eliza demo, connectrpc.eliza.v1.ElizaService). Swift never
// sees tonic/prost or the .proto-generated types — it gets a plain String
// through the same UniFFI async-export/typed-error pattern as get_price_async.

mod eliza {
    tonic::include_proto!("connectrpc.eliza.v1");
}

use eliza::eliza_service_client::ElizaServiceClient;
use eliza::SayRequest;

#[derive(Debug, thiserror::Error, uniffi::Error)]
pub enum ElizaError {
    #[error("network request failed: {reason}")]
    Network { reason: String },

    #[error("invalid input: {reason}")]
    InvalidInput { reason: String },
}

fn validate_free_text(value: &str) -> Result<(), ElizaError> {
    let is_valid = !value.is_empty()
        && value.chars().count() <= 500
        && value.chars().all(|c| !c.is_control());

    if is_valid {
        Ok(())
    } else {
        Err(ElizaError::InvalidInput {
            reason: "input must be 1-500 printable characters".to_string(),
        })
    }
}

#[uniffi::export]
pub async fn ask_eliza(sentence: String) -> Result<String, ElizaError> {
    validate_free_text(&sentence)?;

    ASYNC_RUNTIME
        .spawn(async move {
            let mut client = ElizaServiceClient::connect("https://demo.connectrpc.com")
                .await
                .map_err(|err| ElizaError::Network {
                    reason: err.to_string(),
                })?;

            let response = client
                .say(tonic::Request::new(SayRequest { sentence }))
                .await
                .map_err(|err| ElizaError::Network {
                    reason: err.to_string(),
                })?;

            Ok(response.into_inner().sentence)
        })
        .await
        .expect("eliza task panicked")
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn it_works() {
        assert_eq!(greet("Rust".to_string()), "Hello, Rust! This came from Rust.");
    }
}

#[cfg(test)]
mod network_tests {
    use super::*;

    #[test]
    fn fetches_real_price() {
        match get_price("bitcoin".to_string()) {
            Ok(info) => {
                println!("{:?}", info);
                assert!(info.usd_price > 0.0);
            }
            Err(PriceError::RateLimited) => {
                println!("rate limited, skipping assertion");
            }
            Err(e) => panic!("unexpected error: {e}"),
        }
    }

    #[test]
    fn unknown_coin_returns_invalid_response_error() {
        let result = get_price("this-coin-does-not-exist".to_string());
        match result {
            Err(PriceError::InvalidResponse { .. }) => {}
            Err(PriceError::RateLimited) => {
                println!("rate limited, skipping assertion");
            }
            other => panic!("expected InvalidResponse error, got {other:?}"),
        }
    }
}

#[cfg(test)]
mod async_tests {
    use super::*;

    #[tokio::test]
    async fn fetches_price_async() {
        let result = get_price_async("ethereum".to_string()).await;
        match result {
            Ok(info) => println!("{:?}", info),
            Err(PriceError::RateLimited) => println!("rate limited, skipping"),
            Err(e) => panic!("unexpected error: {e}"),
        }
    }
}

#[cfg(test)]
mod security_tests {
    use super::*;

    #[test]
    fn rejects_url_injection_attempt() {
        let result = get_price("bitcoin&evil=1".to_string());
        assert!(matches!(result, Err(PriceError::InvalidInput { .. })));
    }

    #[test]
    fn rejects_empty_identifier() {
        let result = get_price("".to_string());
        assert!(matches!(result, Err(PriceError::InvalidInput { .. })));
    }

    #[test]
    fn accepts_valid_identifier_with_hyphen() {
        // "usd-coin" is a real CoinGecko id — hyphen must stay allowed.
        assert!(validate_identifier("usd-coin").is_ok());
    }

    #[test]
    fn ticker_constructor_rejects_invalid_symbol() {
        struct NoopListener;
        impl TickerListener for NoopListener {
            fn on_update(&self, _ticker: PriceInfo) {}
            fn on_error(&self, _message: String) {}
        }

        let result = PriceTicker::new(
            vec!["btcusdt;DROP".to_string()],
            std::sync::Arc::new(NoopListener),
        );
        assert!(matches!(result, Err(PriceError::InvalidInput { .. })));
    }
}

#[cfg(test)]
mod eliza_tests {
    use super::*;

    #[tokio::test]
    async fn talks_to_real_eliza_service() {
        let result = ask_eliza("Hello, are you a real gRPC service?".to_string()).await;
        match result {
            Ok(reply) => println!("Eliza says: {reply}"),
            Err(e) => panic!("unexpected error: {e}"),
        }
    }
}
