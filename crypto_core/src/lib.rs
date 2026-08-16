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

// --- Coin details / search / news: three more Node-mediated calls to public
// APIs, backing the Markets/Watchlist/News flows on the Swift side. Same
// principle throughout the project — the Node is the only thing that ever
// calls a public API; Swift only ever sees typed Records.

#[derive(Debug, Clone, uniffi::Record)]
pub struct CoinDetails {
    pub coin_id: String,
    pub name: String,
    pub symbol: String,
    pub description: String,
    pub homepage_url: String,
    pub current_price_usd: f64,
    pub market_cap_usd: f64,
}

#[uniffi::export]
pub fn get_coin_details(coin_id: String) -> Result<CoinDetails, PriceError> {
    validate_identifier(&coin_id)?;

    let url = format!(
        "https://api.coingecko.com/api/v3/coins/{coin_id}?localization=false&tickers=false&market_data=true&community_data=false&developer_data=false"
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

    let name = body["name"]
        .as_str()
        .ok_or_else(|| PriceError::InvalidResponse {
            reason: format!("no name found for '{coin_id}'"),
        })?
        .to_string();
    let symbol = body["symbol"].as_str().unwrap_or_default().to_string();
    let description = body["description"]["en"]
        .as_str()
        .unwrap_or_default()
        .to_string();
    let homepage_url = body["links"]["homepage"][0]
        .as_str()
        .unwrap_or_default()
        .to_string();
    let current_price_usd = body["market_data"]["current_price"]["usd"]
        .as_f64()
        .unwrap_or(0.0);
    let market_cap_usd = body["market_data"]["market_cap"]["usd"]
        .as_f64()
        .unwrap_or(0.0);

    Ok(CoinDetails {
        coin_id,
        name,
        symbol,
        description,
        homepage_url,
        current_price_usd,
        market_cap_usd,
    })
}

#[derive(Debug, Clone, uniffi::Record)]
pub struct CoinSearchResult {
    pub coin_id: String,
    pub name: String,
    pub symbol: String,
    pub market_cap_rank: Option<i64>,
}

fn validate_search_query(value: &str) -> Result<(), PriceError> {
    let is_valid = !value.is_empty()
        && value.chars().count() <= 100
        && value.chars().all(|c| !c.is_control());

    if is_valid {
        Ok(())
    } else {
        Err(PriceError::InvalidInput {
            reason: "search query must be 1-100 printable characters".to_string(),
        })
    }
}

#[uniffi::export]
pub fn search_coins(query: String) -> Result<Vec<CoinSearchResult>, PriceError> {
    validate_search_query(&query)?;

    let encoded_query = urlencoding::encode(&query);
    let url = format!("https://api.coingecko.com/api/v3/search?query={encoded_query}");

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

    let coins = body["coins"]
        .as_array()
        .ok_or_else(|| PriceError::InvalidResponse {
            reason: "no 'coins' field in search response".to_string(),
        })?;

    let results = coins
        .iter()
        .filter_map(|c| {
            Some(CoinSearchResult {
                coin_id: c["id"].as_str()?.to_string(),
                name: c["name"].as_str()?.to_string(),
                symbol: c["symbol"].as_str()?.to_string(),
                market_cap_rank: c["market_cap_rank"].as_i64(),
            })
        })
        .collect();

    Ok(results)
}

#[derive(Debug, Clone, uniffi::Record)]
pub struct NewsArticle {
    pub id: String,
    pub title: String,
    pub summary: String,
    pub url: String,
    pub published_at: String,
}

#[uniffi::export]
pub fn get_news() -> Result<Vec<NewsArticle>, PriceError> {
    let response = ureq::get("https://www.coindesk.com/arc/outboundfeeds/rss/")
        .call()
        .map_err(|err| match err {
            ureq::Error::Status(429, _) => PriceError::RateLimited,
            ureq::Error::Status(code, _) => PriceError::Network {
                reason: format!("HTTP {code}"),
            },
            ureq::Error::Transport(transport) => PriceError::Network {
                reason: transport.to_string(),
            },
        })?;

    let xml = response
        .into_string()
        .map_err(|err| PriceError::InvalidResponse {
            reason: err.to_string(),
        })?;

    parse_rss_items(&xml)
}

fn parse_rss_items(xml: &str) -> Result<Vec<NewsArticle>, PriceError> {
    use quick_xml::events::Event;
    use quick_xml::Reader;

    let mut reader = Reader::from_str(xml);
    reader.config_mut().trim_text(true);

    let mut articles = Vec::new();
    let mut current_tag = String::new();
    let mut in_item = false;

    let mut title = String::new();
    let mut link = String::new();
    let mut guid = String::new();
    let mut pub_date = String::new();
    let mut description = String::new();

    loop {
        let event = reader
            .read_event()
            .map_err(|err| PriceError::InvalidResponse {
                reason: format!("failed to parse RSS feed: {err}"),
            })?;

        match event {
            Event::Eof => break,
            Event::Start(e) => {
                let name = String::from_utf8_lossy(e.name().as_ref()).into_owned();
                if name == "item" {
                    in_item = true;
                    title.clear();
                    link.clear();
                    guid.clear();
                    pub_date.clear();
                    description.clear();
                }
                current_tag = name;
            }
            Event::End(e) => {
                let name = String::from_utf8_lossy(e.name().as_ref()).into_owned();
                if name == "item" && in_item {
                    articles.push(NewsArticle {
                        id: guid.clone(),
                        title: title.clone(),
                        summary: description.clone(),
                        url: link.clone(),
                        published_at: pub_date.clone(),
                    });
                    in_item = false;
                }
                current_tag.clear();
            }
            Event::Text(e) if in_item => {
                let text = e.unescape().unwrap_or_default().into_owned();
                assign_rss_field(
                    &current_tag,
                    text,
                    &mut title,
                    &mut link,
                    &mut guid,
                    &mut pub_date,
                    &mut description,
                );
            }
            Event::CData(e) if in_item => {
                let text = String::from_utf8_lossy(&e.into_inner()).into_owned();
                assign_rss_field(
                    &current_tag,
                    text,
                    &mut title,
                    &mut link,
                    &mut guid,
                    &mut pub_date,
                    &mut description,
                );
            }
            _ => {}
        }
    }

    Ok(articles)
}

fn assign_rss_field(
    tag: &str,
    text: String,
    title: &mut String,
    link: &mut String,
    guid: &mut String,
    pub_date: &mut String,
    description: &mut String,
) {
    match tag {
        "title" => *title = text,
        "link" => *link = text,
        "guid" => *guid = text,
        "pubDate" => *pub_date = text,
        "description" => *description = text,
        _ => {}
    }
}

#[derive(Debug, Clone, uniffi::Record)]
pub struct CoinListing {
    pub coin_id: String,
    pub name: String,
    pub symbol: String,
    pub current_price_usd: f64,
    pub market_cap_rank: Option<i64>,
    pub image_url: String,
}

#[derive(Debug, Clone, uniffi::Record)]
pub struct CoinsPage {
    pub coins: Vec<CoinListing>,
    // Opaque to Swift by design: it's a page number under the hood today,
    // but callers only ever pass back exactly what they were given, the
    // same contract a real cursor-paginated API (Stripe, GitHub GraphQL)
    // exposes even when the backend implements it via offset/page
    // internally. Swift must not parse or construct this string itself.
    pub next_cursor: Option<String>,
}

const COINS_PAGE_SIZE: u32 = 25;

#[uniffi::export]
pub fn get_coins_page(cursor: Option<String>) -> Result<CoinsPage, PriceError> {
    let page: u32 = match cursor {
        Some(ref c) => c.parse().map_err(|_| PriceError::InvalidInput {
            reason: "malformed cursor".to_string(),
        })?,
        None => 1,
    };

    let url = format!(
        "https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd&order=market_cap_desc&per_page={COINS_PAGE_SIZE}&page={page}&sparkline=false"
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

    let body: Vec<serde_json::Value> =
        response
            .into_json()
            .map_err(|err| PriceError::InvalidResponse {
                reason: err.to_string(),
            })?;

    let coins: Vec<CoinListing> = body
        .iter()
        .filter_map(|c| {
            Some(CoinListing {
                coin_id: c["id"].as_str()?.to_string(),
                name: c["name"].as_str()?.to_string(),
                symbol: c["symbol"].as_str()?.to_string(),
                current_price_usd: c["current_price"].as_f64().unwrap_or(0.0),
                market_cap_rank: c["market_cap_rank"].as_i64(),
                image_url: c["image"].as_str().unwrap_or_default().to_string(),
            })
        })
        .collect();

    let next_cursor = if coins.len() as u32 == COINS_PAGE_SIZE {
        Some((page + 1).to_string())
    } else {
        None
    };

    Ok(CoinsPage { coins, next_cursor })
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
// (Buf's public Eliza demo, connectrpc.eliza.v1.ElizaService). Rust owns the
// gRPC transport (tonic handles HTTP/2, TLS, gRPC framing, status codes) but
// deliberately does NOT hand the client a decoded Swift-native type. Instead,
// after tonic/prost decode the response into a Rust struct, it's immediately
// re-encoded back to raw protobuf wire bytes (`prost::Message::encode_to_vec`)
// and those bytes cross the FFI boundary as-is. Swift owns deserialization on
// its side via its own copy of the same eliza.proto (see ../ElizaProtoKit) —
// both ends independently generate code from one shared contract, the same
// way a backend team's proto and a client team's proto stay in sync in a real
// multi-repo setup.

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
pub async fn ask_eliza(sentence: String) -> Result<Vec<u8>, ElizaError> {
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

            // Re-encode the already-decoded response back into raw protobuf
            // wire bytes. Swift decodes these itself using ElizaProtoKit's
            // generated SayResponse — it never sees this Rust struct.
            use prost::Message;
            Ok(response.into_inner().encode_to_vec())
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
            Ok(raw_bytes) => {
                use prost::Message;
                let decoded = eliza::SayResponse::decode(raw_bytes.as_slice())
                    .expect("bytes should decode as a valid SayResponse");
                println!("Eliza says: {}", decoded.sentence);
                assert!(!decoded.sentence.is_empty());
            }
            Err(e) => panic!("unexpected error: {e}"),
        }
    }
}

#[cfg(test)]
mod backend_tests {
    use super::*;

    #[test]
    fn fetches_real_coin_details() {
        let result = get_coin_details("bitcoin".to_string());
        match result {
            Ok(details) => {
                println!("{:?}", details);
                assert_eq!(details.symbol, "btc");
                assert!(details.current_price_usd > 0.0);
                assert!(!details.description.is_empty());
            }
            Err(PriceError::RateLimited) => println!("rate limited, skipping"),
            Err(e) => panic!("unexpected error: {e}"),
        }
    }

    #[test]
    fn searches_real_coins() {
        let result = search_coins("bitcoin".to_string());
        match result {
            Ok(results) => {
                println!("{:?}", results);
                assert!(!results.is_empty());
                assert!(results.iter().any(|r| r.coin_id == "bitcoin"));
            }
            Err(PriceError::RateLimited) => println!("rate limited, skipping"),
            Err(e) => panic!("unexpected error: {e}"),
        }
    }

    #[test]
    fn fetches_real_news() {
        let result = get_news();
        match result {
            Ok(articles) => {
                println!("got {} articles", articles.len());
                if let Some(first) = articles.first() {
                    println!("{:?}", first);
                }
                assert!(!articles.is_empty());
                assert!(!articles[0].title.is_empty());
            }
            Err(e) => panic!("unexpected error: {e}"),
        }
    }

    #[test]
    fn paginates_real_coins() {
        let first = match get_coins_page(None) {
            Ok(page) => page,
            Err(PriceError::RateLimited) => {
                println!("rate limited, skipping");
                return;
            }
            Err(e) => panic!("unexpected error: {e}"),
        };
        assert_eq!(first.coins.len(), COINS_PAGE_SIZE as usize);
        assert!(first.next_cursor.is_some());

        let cursor = first.next_cursor.clone().unwrap();
        let second = get_coins_page(Some(cursor)).expect("second page should succeed");
        assert_eq!(second.coins.len(), COINS_PAGE_SIZE as usize);
        assert_ne!(first.coins[0].coin_id, second.coins[0].coin_id);
    }
}
