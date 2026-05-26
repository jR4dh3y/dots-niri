use niri_ipc::{LogicalOutput, Output};
use waybar_cffi::gtk::gdk::{Monitor, traits::MonitorExt};

/// A filter to check if we should include a window button.
#[derive(Debug, Clone)]
pub enum Filter {
    ShowAll,
    Only(String),
}

impl Filter {
    /// Checks if toplevels on this output should be shown.
    pub fn should_show(&self, output: &str) -> bool {
        match self {
            Self::ShowAll => true,
            Self::Only(only) => only == output,
        }
    }
}

bitflags::bitflags! {
    /// A simple matcher to try to figure out if a Gdk 3 monitor and a Niri output are referring to
    /// the same output.
    #[derive(Debug, Clone, Copy, PartialEq, Eq)]
    pub struct Matcher: u8 {
        const GEOMETRY = 1 << 0;
        const MODEL = 1 << 1;
        const MANUFACTURER = 1 << 2;
    }
}

impl Matcher {
    pub fn new(monitor: &Monitor, output: &Output) -> Self {
        let Some(logical) = &output.logical else {
            tracing::info!(name = output.name, "output does not have a logical output");
            return Self::empty();
        };

        let mut matches = Self::empty();

        matches.set(
            Matcher::GEOMETRY,
            Geometry::from_gdk_monitor(monitor) == Geometry::from_niri_output(logical),
        );

        matches.set(
            Matcher::MODEL,
            match (monitor.model(), &output.model) {
                (Some(gdk_model), niri_model) => gdk_model.as_str() == niri_model,
                (None, niri_model) if niri_model.is_empty() => true,
                _ => false,
            },
        );

        matches.set(
            Matcher::MANUFACTURER,
            match (monitor.manufacturer(), &output.make) {
                (Some(gdk_manufacturer), niri_make) => gdk_manufacturer.as_str() == niri_make,
                (None, niri_make) if niri_make.is_empty() => true,
                _ => false,
            },
        );

        matches
    }
}

#[derive(Debug, Clone, Copy)]
struct Geometry {
    width: i32,
    height: i32,
    x: i32,
    y: i32,
}

impl Geometry {
    fn from_gdk_monitor(monitor: &Monitor) -> Self {
        let geometry = monitor.geometry();
        let scale = monitor.scale_factor();

        Self {
            width: geometry.width() * scale,
            height: geometry.height() * scale,
            x: geometry.x() * scale,
            y: geometry.y() * scale,
        }
    }

    fn from_niri_output(logical: &LogicalOutput) -> Self {
        let LogicalOutput {
            width,
            height,
            scale,
            x,
            y,
            ..
        } = logical;

        // We'll apply the same general calculation as Gdk 3: any fractional component will be
        // rounded up.
        let scale = scale.ceil() as i32;

        Self {
            width: (*width as i32) * scale,
            height: (*height as i32) * scale,
            x: (*x) * scale,
            y: (*y) * scale,
        }
    }
}

impl PartialEq for Geometry {
    fn eq(&self, other: &Self) -> bool {
        // x and y should be the same regardless, but Gdk is apparently... uh, special when it comes
        // to calculating the width and height of the monitor, so we'll define it as "close enough
        // is good enough".
        let x_delta = ((self.width as f64) / (other.width as f64)) - 1.0;
        let y_delta = ((self.height as f64) / (other.height as f64)) - 1.0;

        x_delta.abs() < 0.03 && y_delta.abs() < 0.03 && self.x == other.x && self.y == other.y
    }
}
