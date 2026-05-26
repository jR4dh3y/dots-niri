use thiserror::Error;

#[derive(Error, Debug)]
pub enum Error {
    #[error("niri IPC: {0}")]
    NiriIpc(#[source] std::io::Error),

    #[error("niri reply: {0}")]
    NiriReply(String),

    #[error("unexpected niri response; expected {name}: {response:?}")]
    UnexpectedResponse {
        name: &'static str,
        response: Box<niri_ipc::Response>,
    },

    #[error("window stream send error")]
    WindowStreamSend,
}

impl Error {
    pub(crate) fn unexpected_response(name: &'static str, response: niri_ipc::Response) -> Self {
        Self::UnexpectedResponse {
            name,
            response: Box::new(response),
        }
    }
}
