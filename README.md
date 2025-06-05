# continue.nvim

## DESCRIPTION

Continue is a session manager for Neovim that lets you pick up exactly where you left off across branches, and paths. It supports shada, git, and custom session extensions, making it the most flexible and robust session solution for modern workflows.

## WHY ANOTHER SESSION PLUGIN?

While Neovim ecosystem has several session management plugins, this one offers a distinct apporach by deeply integrating with Neovim Shada system. This allows for more granular and project specific data storage going beyond typical session functionalities.

Here's what sets it apart:

- **Leverages Shada for Project-Specific Data**: Instead of generic session files, this plugin utilizes the power of Shada to store data tailored to each project. This means more than just open buffers and window layouts; it can remember project-specific settings like jumplist, marks, registers, searches and command history.
- **Full Git Integration Including Worktress**: Designed with modern Git workflows in mind, the plugin offers comprehensive support for Git repositories. This includes seamless handling of Git worktrees, ensuring your sessions are accurately managed even across complex branching and experimental setups. It uses Git remotes as a session name key, which helps ensure consistent session loading and saving, even if the project directory is moved or accessed from a different path on your system.
- **Extensible by Design**: Recognizing that different workflows require different data, this plugin is built to be extensible. You can easily write your own custom extensions to save and restore additional data alongside the default session information. For example, this code contains two extensions examples:
  - Store quickfix list contents
  - Store CodeCompanion chat history

## FEATURES

- **Shada session support**: Save/restore jumplist, marks, registers, searches, and command history (project & global scope)
- **Git integration**: Sessions are keyed by git origin/branch, so you can move projects or use worktrees and always get the right session
- **Custom extensions**: Easily add your own session data (e.g., quickfix, plugin state) via a simple Lua interface
- **Auto save/restore**: Never lose your place—sessions are saved/restored automatically
- **Branch & cwd change detection**: Optionally reload sessions on branch/cwd change
- **Session pickers**: Use Telescope, Snacks, or built-in picker to manage sessions

## INSTALLATION

[Lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  'niba/continue',
  -- remember to set lazy as false
  lazy = false,
  -- call setup method or set config = true
  config = true,

  ---@module "continue"
  ---@type Continue.Config
  opts = {}
}
```

## CONFIGURATION

```lua
{
  'niba/continue.nvim',
  lazy = false,
  config = true,

  ---@module "continue"
  ---@type Continue.Config
  opts = {
    auto_save = true, -- enable / disable auto saving session on Neovim exit
    auto_restore = true, -- enable / disable auto restoring session on Neovim startup
    auto_save_min_buffer = 1, -- minimum number of buffers required to trigger auto-save
    auto_restore_on_branch_change = true, -- reload session when a Git branch change is detected

    use_git_branch = true, -- store unique sessions per Git branch
    use_git_host = true, -- identify projects by Git remote host instead of local system path
    git_remote = "origin", -- the Git remote to use as the project base (requires use_git_host = true)

    react_on_cwd_change = false, -- reload session if the current working directory (CWD) changes

    log_level = vim.log.levels.WARN, -- set the logging level
    root_dir = fs.join_paths(vim.fn.stdpath("data"), consts.PLUGIN_NAME), -- path to store session data
    picker = "snacks", -- default picker for session management
    shada = {
      -- project specific data
      -- stores jumplists, marks, searches
      project = "'100,<50,s10,h,:0,/1000",
      -- global neovim data
      -- stores commands history
      global = "!,'0,<0,s10,h,:1000,/0,f0",
    },
    mappings = {
      -- mappings for picker actions
      delete_session = { "i", "<C-X>" },
      save_as_session = { "i", "<C-S>" },
    },
    -- define extensions to save/restore additional data
    extensions = {},
  }
}
```

### Important Notes

- **Shada Handling:** This plugin disables Neovim's default Shada mechanism to manage session data more effectively. Your default Shada data remains safe as this plugin stores its data in a separate location (`root_dir`).
- **Tested Shada Settings:** The provided Shada settings are the ones that have been tested. Shada can be complex; feel free to experiment if you need different behavior, but be aware that other configurations might not work as expected.

---

### Information & Usage Details

- **Auto Session Restoration Conditions:**
  - Automatic session restoration works when Neovim is started **without arguments** or **with a directory as an argument**.
    - `nvim` - Restores session.
    - `nvim .` - Restores session.
    - `nvim file.txt` - **Does not** restore session (to allow opening specific files without interference).
- **Project Identification with Git:**
  - By default, the plugin uses the Git remote address to generate a unique project ID. This allows sessions to be restored even if the project's local path changes or when you open a branch in a different Git worktree.
- **Git Branch Specific Sessions:**
  - If `use_git_branch` is enabled, each branch maintains its own session data. The plugin can detect branch changes and automatically restore the session for the newly checked-out branch.
- **Disabling Auto Restore Temporarily:**
  - If you encounter issues with auto-restoring a session, you can temporarily disable it by launching Neovim with a specific command:
    ```bash
    nvim --cmd "let g:auto_continue = v:false"
    ```

## Usage

### Usage

#### API

You can interact with `continue.nvim` programmatically:

```lua
local continue_api = require("continue")

-- Save the current session
continue_api.save()

-- Load a session (typically used with a picker or specific identifier)
continue_api.load()

-- Delete a session
continue_api.delete()

-- Search/Pick a session to load
continue_api.search()

-- Toggle the auto-save feature on/off
continue_api.toggle_auto_save()
```

#### Commands

The plugin also provides the following user commands:

- `:ContinueLoad` - Load a session (often opens a picker).
- `:ContinueSave` - Save the current session.
- `:ContinueDelete` - Delete a session (often opens a picker).
- `:ContinueToggleAutoSave` - Toggle the auto-save feature.
- `:ContinueSearch` - Search and pick a session to load.

---

### Hooks

You can define hook functions to execute custom actions before or after saving/restoring sessions.

```lua
---@field pre_save? fun(args: Continue.Config.HookArgs): nil
---@field post_save? fun(args: Continue.Config.HookArgs): nil
---@field pre_restore? fun(args: Continue.Config.HookArgs): nil
---@field post_restore? fun(args: Continue.Config.HookArgs): nil
```

**Example: Auto-open Neo-tree after restoring a session**

Add this to your `opts` configuration:

```lua
opts = {
  -- ... other options
  hooks = {
    post_restore = function()
      vim.cmd([[Neotree filesystem show]])
    end,
  },
  -- ... other options
}
```

### Extensions

Extensions provide an easy way to save and restore additional project-specific data without needing to manage the underlying session mechanics. Data handled by extensions is stored as JSON.

`continue.nvim` includes two built-in extensions:

- **`quickfix`**: Saves and restores visible quickfix lists.
- **`codecompanion`**: Saves and restores project-related chats from the [codecompanion.nvim](https://github.com/nirae/codecompanion.nvim) plugin. (Note: This works for basic chats; functionality with tools or extensive context data has not been fully tested).

**Enabling Extensions:**

To use an extension, add its module path string or a function that returns the extension module to the `extensions` list in your `opts`:

```lua
opts = {
  -- ... other options
  extensions = {
    "continue.sessions.extensions.quickfix",
    function()
      return require("continue.sessions.extensions.codecompanion")
    end,
  },
  -- ... other options
}
```

**Extension Interface:**

If you want to create your own extension, it needs to implement the following interface:

```lua
---@class Continue.ExtensionHandler
---@field id string -- A unique ID used in the filename. Be mindful of special characters.
---@field save fun(opts: SessionOpts): table<string, any> -- Returns a Lua table (serializable to JSON) to be saved.
---@field load fun(data: table<string, any>, opts: SessionOpts): nil -- Receives the previously saved JSON data (parsed as a Lua table).
---@field enabled? fun(): boolean -- Optional function to determine if the extension should be active.
```
