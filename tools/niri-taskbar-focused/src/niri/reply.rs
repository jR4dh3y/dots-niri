/// Checks that the given [`niri_ipc::Reply`] contains the expected [`niri_ipc::Response`] variant
/// and returns it, otherwise [`crate::error::Error::NiriReply`] is returned.
macro_rules! typed {
    (Handled, $reply:expr) => {{
        match $reply {
            Ok(niri_ipc::Response::Handled) => Ok(()),
            Ok(response) => Err($crate::error::Error::unexpected_response(
                stringify!($variant),
                response,
            )),
            Err(e) => Err($crate::error::Error::NiriReply(e)),
        }
    }};
    ($variant:ident, $reply:expr) => {{
        match $reply {
            Ok(niri_ipc::Response::$variant(inner)) => Ok(inner),
            Ok(response) => Err($crate::error::Error::unexpected_response(
                stringify!($variant),
                response,
            )),
            Err(e) => Err($crate::error::Error::NiriReply(e)),
        }
    }};
}

pub(super) use typed;
