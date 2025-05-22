--- @class RelVirtOptions
--- @field ignored_filetypes string[] Pattern-matching filetypes to skip rendering
--- @field space_reserve integer Extra columns to leave empty at end of line
--- @field show_on_blank_lines boolean Whether to show virtual number on empty lines
--- @field show_on_cursor_line boolean Whether to show number on the current line
--- @field min_line_distance integer Lines closer than this to the cursor are hidden
--- @field format_number fun(rel: integer): string | [ string, string ] Format and optionally highlight the virtual number

local M = {}

--- @type RelVirtOptions
M.opts = {
    ignored_filetypes = {},
    space_reserve = 0,
    show_on_blank_lines = false,
    show_on_cursor_line = true,
    min_line_distance = 1,
    format_number = function(rel)
        return { tostring(math.abs(rel)), "LineNr" }
    end,
}

local api = vim.api
local ns = api.nvim_create_namespace("rel_lines")

-- Global toggle flag
vim.g.relvirt_enabled = true

--- Check if a buffer line is blank
--- @param buf integer
--- @param lnum integer
--- @return boolean
local function is_blank(buf, lnum)
    local line = api.nvim_buf_get_lines(buf, lnum, lnum + 1, false)[1] or ""
    return line:match("^%s*$") ~= nil
end

--- @param win integer
--- @return integer
local function get_window_width(win)
    return api.nvim_win_get_width(win or 0)
end

--- @param buf integer
--- @param lnum integer
--- @return integer
local function get_line_width(buf, lnum)
    local line = api.nvim_buf_get_lines(buf, lnum, lnum + 1, false)[1] or ""
    return vim.fn.strdisplaywidth(line)
end

--- Compute display width of a virt_text spec
--- @param virt_text { [1]: string, [2]: string }[]
--- @return integer
local function virtual_text_width(virt_text)
    local total = 0
    for _, chunk in ipairs(virt_text) do
        total = total + vim.fn.strdisplaywidth(chunk[1])
    end
    return total
end

--- Sum the widths of all virtual texts on the given line
--- @param buf integer
--- @param lnum integer
--- @return integer
local function get_total_virtual_text_width(buf, lnum)
    local marks = api.nvim_buf_get_extmarks(buf, -1, { lnum, 0 }, { lnum, -1 }, { details = true })
    local width = 0
    for _, mark in ipairs(marks) do
        local details = mark[4]
        if details and details.virt_text then
            width = width + virtual_text_width(details.virt_text)
        end
    end
    return width
end

--- Determine whether the line should be suppressed due to visual overflow
--- @param buf integer
--- @param lnum integer
--- @param win integer
--- @param reserve integer
--- @return boolean
local function should_suppress_number(buf, lnum, win, reserve)
    reserve = reserve or M.opts.space_reserve
    local line_width = get_line_width(buf, lnum)
    local virt_width = get_total_virtual_text_width(buf, lnum)
    local win_width = get_window_width(win)
    return (line_width + virt_width + reserve) >= win_width
end

--- Render a relative number for a single line
--- @param buf integer
--- @param lnum integer
--- @param cur integer Cursor line number (0-based)
--- @param win integer
local function render_line(buf, lnum, cur, win)
    local rel = lnum - cur
    local suppress = (rel == 0 and not M.opts.show_on_cursor_line)
        or (math.abs(rel) <= M.opts.min_line_distance)
        or (not M.opts.show_on_blank_lines and is_blank(buf, lnum))
        or should_suppress_number(buf, lnum, win, M.opts.space_reserve)
    if suppress then
        return
    end

    local formatted = M.opts.format_number(rel)
    local text, hl
    if type(formatted) == "table" then
        text, hl = unpack(formatted)
    else
        text, hl = formatted, "LineNr"
    end

    api.nvim_buf_set_extmark(buf, ns, lnum, 0, {
        id = lnum + 1,
        virt_text = { { text, hl } },
        virt_text_pos = "eol",
        hl_mode = "combine",
    })
end

--- Re-render all lines in the current window view
--- @param buf integer
local function refresh(buf)
    local win = api.nvim_get_current_win()
    local cur = api.nvim_win_get_cursor(win)[1] - 1
    local topline = vim.fn.line("w0", win) - 1
    local botline = vim.fn.line("w$", win) - 1
    local lastline = api.nvim_buf_line_count(buf) - 1

    topline = math.max(0, topline)
    botline = math.min(lastline, botline)

    api.nvim_buf_clear_namespace(buf, ns, topline, botline + 1)

    for l = topline, botline do
        render_line(buf, l, cur, win)
    end
end

--- Check if the filetype of the buffer is ignored
--- @param buf integer
--- @return boolean
local function is_ignored_filetype(buf)
    local ft = vim.bo[buf].filetype
    for _, pattern in ipairs(M.opts.ignored_filetypes or {}) do
        if ft:match("^" .. pattern .. "$") then
            return true
        end
    end
    return false
end

--- Setup autocommands for refreshing extmarks or clearing them
local function setup_autocmd()
    api.nvim_create_autocmd({ "BufWinEnter", "CursorMoved", "WinScrolled" }, {
        group = api.nvim_create_augroup("RelVirt", { clear = true }),
        callback = function(ev)
            if is_ignored_filetype(ev.buf) then
                return
            end
            if vim.g.relvirt_enabled then
                refresh(ev.buf)
            else
                api.nvim_buf_clear_namespace(ev.buf, ns, 0, -1)
            end
        end,
    })
end

--- Toggle the plugin on/off globally
function M.toggle()
    vim.g.relvirt_enabled = not vim.g.relvirt_enabled
    if vim.g.relvirt_enabled then
        vim.cmd("doautocmd <nomodeline> CursorMoved")
    else
        api.nvim_buf_clear_namespace(0, ns, 0, -1)
    end
end

--- Initialize the plugin
--- @param opts RelVirtOptions?
function M.setup(opts)
    M.opts = vim.tbl_deep_extend("force", M.opts, opts or {})
    api.nvim_create_user_command("RelvirtToggle", M.toggle, {})
    setup_autocmd()
end

return M
