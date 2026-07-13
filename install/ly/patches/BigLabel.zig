const BigLabel = @This();

const std = @import("std");
const Allocator = std.mem.Allocator;

const ly_core = @import("ly-core");
const interop = ly_core.interop;

const en = @import("bigLabelLocales/en.zig");
const fa = @import("bigLabelLocales/fa.zig");
const Cell = @import("../Cell.zig");
const Position = @import("../Position.zig");
const TerminalBuffer = @import("../TerminalBuffer.zig");
const Widget = @import("../Widget.zig");

pub const CHAR_WIDTH = 5;
pub const CHAR_HEIGHT = 5;
pub const CHAR_SIZE = CHAR_WIDTH * CHAR_HEIGHT;
pub const X: u32 = if (ly_core.interop.supportsUnicode()) 0x2593 else '#';
pub const O: u32 = 0;

// zig fmt: off
pub const LocaleChars = struct {
    ZERO:   [CHAR_SIZE]u21,
    ONE:    [CHAR_SIZE]u21,
    TWO:    [CHAR_SIZE]u21,
    THREE:  [CHAR_SIZE]u21,
    FOUR:   [CHAR_SIZE]u21,
    FIVE:   [CHAR_SIZE]u21,
    SIX:    [CHAR_SIZE]u21,
    SEVEN:  [CHAR_SIZE]u21,
    EIGHT:  [CHAR_SIZE]u21,
    NINE:   [CHAR_SIZE]u21,
    S:      [CHAR_SIZE]u21,
    E:      [CHAR_SIZE]u21,
    P:      [CHAR_SIZE]u21,
    A:      [CHAR_SIZE]u21,
    M:      [CHAR_SIZE]u21,
};
// zig fmt: on

pub const BigLabelLocale = enum {
    en,
    fa,
};

instance: ?Widget = null,
allocator: ?Allocator = null,
buffer: *TerminalBuffer,
text: []const u8,
max_width: ?usize,
fg: u32,
bg: u32,
locale: BigLabelLocale,
update_fn: ?*const fn (*BigLabel, *anyopaque) anyerror!void,
calculate_timeout_fn: ?*const fn (*BigLabel, *anyopaque) anyerror!?usize,
component_pos: Position,
children_pos: Position,

pub fn init(
    buffer: *TerminalBuffer,
    text: []const u8,
    max_width: ?usize,
    fg: u32,
    bg: u32,
    locale: BigLabelLocale,
    update_fn: ?*const fn (*BigLabel, *anyopaque) anyerror!void,
    calculate_timeout_fn: ?*const fn (*BigLabel, *anyopaque) anyerror!?usize,
) BigLabel {
    return .{
        .instance = null,
        .allocator = null,
        .buffer = buffer,
        .text = text,
        .max_width = max_width,
        .fg = fg,
        .bg = bg,
        .locale = locale,
        .update_fn = update_fn,
        .calculate_timeout_fn = calculate_timeout_fn,
        .component_pos = TerminalBuffer.START_POSITION,
        .children_pos = TerminalBuffer.START_POSITION,
    };
}

pub fn deinit(self: *BigLabel) void {
    if (self.allocator) |allocator| allocator.free(self.text);
}

pub fn widget(self: *BigLabel) *Widget {
    if (self.instance) |*instance| return instance;
    self.instance = Widget.init(
        "BigLabel",
        null,
        self,
        deinit,
        null,
        draw,
        update,
        null,
        calculateTimeout,
    );
    return &self.instance.?;
}

pub fn setTextAlloc(
    self: *BigLabel,
    allocator: Allocator,
    comptime fmt: []const u8,
    args: anytype,
) !void {
    self.text = try std.fmt.allocPrint(allocator, fmt, args);
    self.allocator = allocator;
}

pub fn setTextBuf(
    self: *BigLabel,
    buffer: []u8,
    comptime fmt: []const u8,
    args: anytype,
) !void {
    self.text = try std.fmt.bufPrint(buffer, fmt, args);
    self.allocator = null;
}

pub fn setText(self: *BigLabel, text: []const u8) void {
    self.text = text;
    self.allocator = null;
}

pub fn positionX(self: *BigLabel, original_pos: Position) void {
    self.component_pos = original_pos;
    self.children_pos = original_pos.addX(TerminalBuffer.strWidth(self.text) * CHAR_WIDTH);
}

pub fn positionY(self: *BigLabel, original_pos: Position) void {
    self.component_pos = original_pos;
    self.children_pos = original_pos.addY(CHAR_HEIGHT);
}

pub fn positionXY(self: *BigLabel, original_pos: Position) void {
    self.component_pos = original_pos;
    self.children_pos = Position.init(
        TerminalBuffer.strWidth(self.text) * CHAR_WIDTH,
        CHAR_HEIGHT,
    ).add(original_pos);
}

pub fn childrenPosition(self: BigLabel) Position {
    return self.children_pos;
}

fn draw(self: *BigLabel) void {
    if (self.text.len == 0) return;

    // Solid background panel + border behind the big clock.
    // Empty digit cells use ch=0 and are skipped by Cell.put, so without this
    // fill the animation shows through the clock.
    const pad: usize = 1;
    const content_w = self.text.len * (CHAR_WIDTH + 1) - 1;
    const content_h: usize = CHAR_HEIGHT;
    const panel_w = content_w + (2 * pad);
    const panel_h = content_h + (2 * pad);
    const origin_x = if (self.component_pos.x >= pad) self.component_pos.x - pad else 0;
    const origin_y = if (self.component_pos.y >= pad) self.component_pos.y - pad else 0;

    // Fill panel (use space so Cell.put actually paints the background)
    const fill = Cell.init(' ', self.fg, self.bg);
    var yy: usize = 0;
    while (yy < panel_h) : (yy += 1) {
        var xx: usize = 0;
        while (xx < panel_w) : (xx += 1) {
            const x = origin_x + xx;
            const y = origin_y + yy;
            if (x < self.buffer.width and y < self.buffer.height) {
                fill.put(x, y);
            }
        }
    }

    // Border matching the login box style
    if (panel_w >= 2 and panel_h >= 2) {
        const right = origin_x + panel_w - 1;
        const bottom = origin_y + panel_h - 1;
        const bfg = self.buffer.border_fg;
        const bbg = self.bg;
        var tl = Cell.init(self.buffer.box_chars.left_up, bfg, bbg);
        var tr = Cell.init(self.buffer.box_chars.right_up, bfg, bbg);
        var bl = Cell.init(self.buffer.box_chars.left_down, bfg, bbg);
        var br = Cell.init(self.buffer.box_chars.right_down, bfg, bbg);
        var top = Cell.init(self.buffer.box_chars.top, bfg, bbg);
        var bot = Cell.init(self.buffer.box_chars.bottom, bfg, bbg);
        var left = Cell.init(self.buffer.box_chars.left, bfg, bbg);
        var rightc = Cell.init(self.buffer.box_chars.right, bfg, bbg);

        if (origin_x < self.buffer.width and origin_y < self.buffer.height) tl.put(origin_x, origin_y);
        if (right < self.buffer.width and origin_y < self.buffer.height) tr.put(right, origin_y);
        if (origin_x < self.buffer.width and bottom < self.buffer.height) bl.put(origin_x, bottom);
        if (right < self.buffer.width and bottom < self.buffer.height) br.put(right, bottom);

        var x: usize = origin_x + 1;
        while (x < right) : (x += 1) {
            if (x < self.buffer.width) {
                if (origin_y < self.buffer.height) top.put(x, origin_y);
                if (bottom < self.buffer.height) bot.put(x, bottom);
            }
        }
        var y: usize = origin_y + 1;
        while (y < bottom) : (y += 1) {
            if (y < self.buffer.height) {
                if (origin_x < self.buffer.width) left.put(origin_x, y);
                if (right < self.buffer.width) rightc.put(right, y);
            }
        }
    }

    for (self.text, 0..) |c, i| {
        const clock_cell = clockCell(
            c,
            self.fg,
            self.bg,
            self.locale,
        );

        alphaBlit(
            self.component_pos.x + i * (CHAR_WIDTH + 1),
            self.component_pos.y,
            self.buffer.width,
            self.buffer.height,
            clock_cell,
        );
    }
}

fn update(self: *BigLabel, context: *anyopaque) !void {
    if (self.update_fn) |update_fn| {
        return @call(
            .auto,
            update_fn,
            .{ self, context },
        );
    }
}

fn calculateTimeout(self: *BigLabel, ctx: *anyopaque) !?usize {
    if (self.calculate_timeout_fn) |calculate_timeout_fn| {
        return @call(
            .auto,
            calculate_timeout_fn,
            .{ self, ctx },
        );
    }

    return null;
}

fn clockCell(char: u8, fg: u32, bg: u32, locale: BigLabelLocale) [CHAR_SIZE]Cell {
    var cells: [CHAR_SIZE]Cell = undefined;

    //@divTrunc(time.microseconds, 500000) != 0)
    const clock_chars = toBigNumber(char, locale);
    for (0..cells.len) |i| cells[i] = Cell.init(clock_chars[i], fg, bg);

    return cells;
}

fn alphaBlit(x: usize, y: usize, tb_width: usize, tb_height: usize, cells: [CHAR_SIZE]Cell) void {
    if (x + CHAR_WIDTH >= tb_width or y + CHAR_HEIGHT >= tb_height) return;

    for (0..CHAR_HEIGHT) |yy| {
        for (0..CHAR_WIDTH) |xx| {
            const cell = cells[yy * CHAR_WIDTH + xx];
            cell.put(x + xx, y + yy);
        }
    }
}

fn toBigNumber(char: u8, locale: BigLabelLocale) [CHAR_SIZE]u21 {
    const locale_chars = switch (locale) {
        .fa => fa.locale_chars,
        .en => en.locale_chars,
    };
    return switch (char) {
        '0' => locale_chars.ZERO,
        '1' => locale_chars.ONE,
        '2' => locale_chars.TWO,
        '3' => locale_chars.THREE,
        '4' => locale_chars.FOUR,
        '5' => locale_chars.FIVE,
        '6' => locale_chars.SIX,
        '7' => locale_chars.SEVEN,
        '8' => locale_chars.EIGHT,
        '9' => locale_chars.NINE,
        'p', 'P' => locale_chars.P,
        'a', 'A' => locale_chars.A,
        'm', 'M' => locale_chars.M,
        ':' => locale_chars.S,
        else => locale_chars.E,
    };
}
