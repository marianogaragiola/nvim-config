# Neovim config

Single-file Neovim configuration (`init.lua`) using [lazy.nvim](https://github.com/folke/lazy.nvim),
set up mainly for Python (uv), plus JavaScript/TypeScript, Terraform, Rust, Go, Lua, Bash and YAML.

The previous kickstart-based config is kept in `init-back.lua` for reference.

## Requirements

- Neovim **0.11+**
- `git`, `make` and a C compiler (treesitter parsers, telescope-fzf-native)
- [ripgrep](https://github.com/BurntSushi/ripgrep) (`brew install ripgrep`) for live grep
- Node.js (Copilot, TypeScript/Bash/YAML language servers)
- A [Nerd Font](https://www.nerdfonts.com/) selected in your terminal, e.g. **Hack Nerd Font Mono**
  (iTerm: Settings → Profiles → Text → Font)
- Optional: `uv` for Python projects, `cargo` for Rust, `terraform` for Terraform formatting

## Install

```sh
git clone <this repo> ~/.config/nvim
nvim
```

On first start lazy.nvim installs every plugin, and Mason installs the language servers and tools.
Wait for both to finish, then restart Neovim. Useful commands:

| Command | What it does |
| --- | --- |
| `:Lazy` | Plugin manager UI |
| `:Lazy sync` | Install, update and clean plugins (updates `lazy-lock.json`) |
| `:Mason` | Language servers / tools UI |
| `:checkhealth` | Diagnose problems |
| `:LspInfo` / `:checkhealth vim.lsp` | Which servers are attached to the current buffer |
| `:ConformInfo` | Formatters for the current buffer |

## Plugins

| Area | Plugin |
| --- | --- |
| Plugin manager | lazy.nvim |
| Colorschemes | everforest (default), gruvbox.nvim — see [Colorscheme](#colorscheme) |
| Fuzzy finder | telescope.nvim (+ fzf-native, ui-select) |
| File explorer | neo-tree.nvim (+ nvim-window-picker) |
| Buffer tabs / statusline | bufferline.nvim / mini.statusline |
| LSP | nvim-lspconfig, mason.nvim, mason-lspconfig, mason-tool-installer, fidget.nvim, lazydev.nvim |
| Completion | blink.cmp + friendly-snippets + blink-copilot (copilot.lua) |
| Formatting | conform.nvim |
| Git | gitsigns.nvim, diffview.nvim |
| Lists | trouble.nvim (diagnostics, references, symbols, quickfix) |
| Syntax | nvim-treesitter (pinned to the `master` branch) |
| Editing | mini.ai, mini.surround, nvim-autopairs, vim-sleuth, todo-comments, indent-blankline |
| AI | claude-chat.nvim |
| Help | which-key.nvim (press `<Space>` and wait to see available keys) |

## Language servers

Only the servers listed in the `servers` table in `init.lua` are enabled. Anything else installed in
Mason stays off.

| Language | Servers | Formatter (`<leader>f`) |
| --- | --- | --- |
| Python | basedpyright, ruff | ruff (organize imports + format) |
| JavaScript / TypeScript | ts_ls | ts_ls |
| Terraform | terraformls, tflint | terraform fmt (via terraformls) |
| Rust | rust_analyzer | rustfmt (via rust_analyzer) |
| Go | gopls | gopls |
| Lua | lua_ls | stylua |
| Bash / YAML | bashls / yamlls | — |

### Python and uv virtualenvs

basedpyright is pointed at the right interpreter automatically, so hover docs, completion and
go-to-definition resolve packages installed with `uv add` / `uv sync`:

1. `$VIRTUAL_ENV`, if a venv is activated (e.g. `source .venv/bin/activate` or `uv run nvim`)
2. otherwise `<project root>/.venv/bin/python` (project root = nearest `pyproject.toml`, `setup.py`, … or `.git`)
3. otherwise the system Python

Type checking uses basedpyright's `standard` mode. ruff handles linting, formatting and import sorting
and reads `[tool.ruff]` from `pyproject.toml`. Trailing whitespace is stripped on save in `.py` files.

If you create the `.venv` after opening a file, run `:LspRestart`.

### Adding a language server

1. Find the server name in `:help lspconfig-all` (or `:Mason`).
2. Add it to the `servers` table in `init.lua`, e.g. `clangd = {},` (add `settings` if needed).
3. Restart Neovim. Mason installs it and it is enabled automatically.

## Keymaps

Leader is `<Space>`. Press `<Space>` and wait to see everything in which-key; `<leader>sk` searches all keymaps.

### General

| Keys | Action |
| --- | --- |
| `<Esc>` / `<leader>h` | Clear search highlight |
| `<leader>R` | Reload config (see below) |
| `<C-h/j/k/l>` | Move between windows |
| `<S-h>` / `<S-l>` | Previous / next buffer |
| `<leader>bc` | Close buffer (keeps the window) |
| `<leader>e` | Toggle file explorer |
| `J` / `K` (visual), `<A-j>` / `<A-k>` (visual) | Move selected lines down / up |
| `<Esc><Esc>` (terminal) | Leave terminal mode |

### Search (Telescope)

| Keys | Action |
| --- | --- |
| `<leader>sf` | Files (includes hidden/ignored, skips `.git/`, `.venv/`, `node_modules`) |
| `<leader>sg` | Live grep |
| `<leader>sw` | Grep word under cursor |
| `<leader><leader>` | Open buffers |
| `<leader>s.` | Recent files |
| `<leader>/` | Fuzzy search in current buffer |
| `<leader>s/` | Grep in open files |
| `<leader>sd` | Diagnostics |
| `<leader>sh` / `<leader>sk` | Help tags / keymaps |
| `<leader>sn` | Neovim config files |
| `<leader>sc` | Pick colorscheme (live preview, remembered) |
| `<leader>sr` | Resume last search |
| `<leader>ss` | List Telescope pickers |

Inside Telescope: `<C-j>` / `<C-k>` move, `<C-n>` / `<C-p>` prompt history, `<C-c>` close.

### LSP (when a server is attached)

| Keys | Action |
| --- | --- |
| `K` (Shift+k) | Hover documentation (floating window) |
| `gd` | Go to definition |
| `gr` | References |
| `gI` | Implementation |
| `gD` | Declaration |
| `<leader>D` | Type definition |
| `<leader>ds` / `<leader>ws` | Document / workspace symbols |
| `<leader>rn` | Rename |
| `<leader>ca` | Code action |
| `<leader>f` | Format buffer |
| `<leader>th` | Toggle inlay hints |
| `<leader>df` | Diagnostic under cursor (float) |
| `<leader>q` | Diagnostics to location list |
| `<C-t>` | Jump back after go-to |

### Completion (insert mode)

| Keys | Action |
| --- | --- |
| `<C-j>` / `<C-n>` | Next item |
| `<C-k>` / `<C-p>` | Previous item |
| `<C-y>` | Accept |
| `<C-Space>` | Open menu / toggle docs |
| `<C-e>` | Close menu |
| `<C-b>` / `<C-f>` | Scroll docs |
| `<C-l>` / `<C-h>` | Next / previous snippet placeholder |

Copilot suggestions appear in the completion menu (not as inline ghost text). Run `:Copilot auth` once to sign in.

### Git (gitsigns)

| Keys | Action |
| --- | --- |
| `]c` / `[c` | Next / previous change |
| `<leader>gs` | Stage / unstage hunk (works on a visual selection too) |
| `<leader>gr` | Reset hunk (works on a visual selection too) |
| `<leader>gp` | Preview hunk |
| `<leader>gb` | Blame line |
| `<leader>gd` | Diff against index |
| `<leader>tb` | Toggle inline blame |
| `<leader>gv` | Toggle diffview (all uncommitted changes, side by side; also shows merge conflicts) |
| `<leader>gh` | History of the current file |
| `<leader>gH` | History of the whole repo |

In diffview: `q` closes it, `<Tab>` / `<S-Tab>` go to the next / previous file, `-` stages / unstages the
file in the file panel, `g?` shows all keys.

### Lists (Trouble)

| Keys | Action |
| --- | --- |
| `<leader>xx` | Diagnostics for the whole project |
| `<leader>xb` | Diagnostics for the current buffer |
| `<leader>xs` | Symbols outline |
| `<leader>xr` | LSP definitions / references (right side) |
| `<leader>xq` / `<leader>xl` | Quickfix / location list |

All of them toggle. Inside the list: `<CR>` jumps to the item, `o` jumps and closes, `q` closes, `?` shows help.

### Claude

| Keys | Action |
| --- | --- |
| `<leader>ai` | Toggle Claude chat sidebar |
| `<leader>af` | Add current file to the chat |

### Text objects and surround (mini.nvim)

- `va)` select around parens, `yinq` yank inside next quote, `ci'` change inside quotes
- `saiw)` surround word with parens, `sd'` delete surrounding quotes, `sr)'` replace `)` with `'`

### File explorer (neo-tree)

`<CR>` open, `s` / `S` vertical / horizontal split, `a` add (end with `/` for a directory), `d` delete,
`r` rename, `y` / `x` / `p` copy / cut / paste, `H` toggle hidden files, `/` filter, `w` open with window picker, `?` help.

## Colorscheme

Both [everforest](https://github.com/sainnhe/everforest) and
[gruvbox](https://github.com/ellisonleao/gruvbox.nvim) are installed. Switch with `<leader>sc` (moving through
the list previews each one; `<CR>` keeps it, `<Esc>` goes back) or with `:colorscheme <name>`.

The last colorscheme you pick is saved to `~/.local/state/nvim/colorscheme` and used on the next start.
That file lives outside this repo, so switching never creates a git change and each machine keeps its own
choice. Delete it to go back to the default (`default_colorscheme` in `init.lua`, currently `everforest`).

- everforest contrast: set `vim.g.everforest_background` to `'hard'`, `'medium'` or `'soft'` in its plugin spec.
- Light variants: `:set background=light` (works for both themes; not remembered, `init.lua` sets `dark` on start).
- Adding another theme: add its plugin to the colorschemes section in `init.lua` and restart; it then shows
  up in `<leader>sc`.

## Reloading the config

`<leader>R` re-sources `init.lua` without restarting: options, keymaps, autocommands and diagnostic
settings are re-applied immediately.

lazy.nvim does not support running its setup twice, so plugin specs are **not** re-applied. After
changing a plugin's settings, either restart Neovim or run `:Lazy reload <plugin>` (e.g.
`:Lazy reload gitsigns.nvim`). After changing LSP server settings, restart Neovim.

## Updating

- `:Lazy sync` updates plugins and records the versions in `lazy-lock.json`. Commit that file so the
  same versions are used everywhere; `:Lazy restore` goes back to the versions in the lockfile.
- `:MasonUpdate` / `:Mason` (press `U`) updates language servers and tools.
- `:TSUpdate` updates treesitter parsers.

## Troubleshooting

- **`K` says "No Python documentation found" or opens a split:** no language server is attached, so
  Neovim fell back to `pydoc`. Check `:checkhealth vim.lsp`, make sure the server is installed in
  `:Mason`, and run `:Lazy sync` (an old `nvim-lspconfig` in `lazy-lock.json` has no server configs).
- **Imports from your project's packages are unresolved:** make sure `.venv` exists in the project root
  (`uv sync`), then `:LspRestart`.
- **Icons show as boxes:** your terminal font is not a Nerd Font.
- **Treesitter errors after an update:** nvim-treesitter must stay on the `master` branch (already
  pinned in `init.lua`); run `:TSUpdate`.
