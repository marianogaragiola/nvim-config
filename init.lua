-- Neovim config (Neovim 0.11+, lazy.nvim)

-- [[ Leader ]] must be set before plugins load
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

vim.g.have_nerd_font = true

-- [[ Options ]]
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.mouse = 'a'
vim.opt.showmode = false -- shown in statusline
vim.schedule(function()
  vim.opt.clipboard = 'unnamedplus'
end)
vim.opt.breakindent = true
vim.opt.undofile = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.signcolumn = 'yes'
vim.opt.updatetime = 250
vim.opt.timeoutlen = 300
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.list = true
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }
vim.opt.inccommand = 'split'
vim.opt.cursorline = true
vim.opt.scrolloff = 10
vim.opt.colorcolumn = '80'
vim.opt.termguicolors = true
vim.o.background = 'dark'

-- [[ Keymaps ]]
local map = vim.keymap.set

map('n', '<Esc>', '<cmd>nohlsearch<CR>')
map('n', '<leader>h', '<cmd>nohlsearch<CR>', { desc = 'Clear highlights' })
map('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

-- Diagnostics
map('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Diagnostic [Q]uickfix list' })
map('n', '<leader>df', vim.diagnostic.open_float, { desc = '[D]iagnostic [F]loat' })

-- Window navigation
map('n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus to the left window' })
map('n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus to the right window' })
map('n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus to the lower window' })
map('n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus to the upper window' })

-- Move selected text up/down
map('x', 'J', ":move '>+1<CR>gv-gv", { silent = true, desc = 'Move selection down' })
map('x', 'K', ":move '<-2<CR>gv-gv", { silent = true, desc = 'Move selection up' })
map('x', '<A-j>', ":move '>+1<CR>gv-gv", { silent = true, desc = 'Move selection down' })
map('x', '<A-k>', ":move '<-2<CR>gv-gv", { silent = true, desc = 'Move selection up' })

-- Buffers
map('n', '<S-l>', '<cmd>bnext<CR>', { desc = 'Next buffer' })
map('n', '<S-h>', '<cmd>bprevious<CR>', { desc = 'Previous buffer' })
map('n', '<leader>bc', function()
  require('mini.bufremove').delete(0, false) -- asks before dropping unsaved changes
end, { desc = '[B]uffer [C]lose' })

-- Reload config: options, keymaps, autocmds, diagnostics.
-- Plugin specs are not re-applied; use `:Lazy reload <plugin>` for those.
map('n', '<leader>R', function()
  local ok, err = pcall(vim.cmd.source, vim.env.MYVIMRC)
  if ok then
    vim.notify('Config reloaded', vim.log.levels.INFO)
  else
    vim.notify('Config reload failed:\n' .. err, vim.log.levels.ERROR)
  end
end, { desc = '[R]eload config' })

-- Neovim 0.11 ships default LSP maps starting with `gr` (grn, grr, gri, gra).
-- They make our `gr` (references) wait for timeoutlen, so remove them.
for _, lhs in ipairs { 'grn', 'grr', 'gri', 'gra' } do
  pcall(vim.keymap.del, 'n', lhs)
end
pcall(vim.keymap.del, 'x', 'gra')

-- [[ Autocommands ]]
local augroup = vim.api.nvim_create_augroup('user-config', { clear = true })

vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking text',
  group = augroup,
  callback = function()
    vim.hl.on_yank()
  end,
})

vim.api.nvim_create_autocmd('BufWritePre', {
  desc = 'Strip trailing whitespace in Python files',
  group = augroup,
  pattern = '*.py',
  callback = function()
    local view = vim.fn.winsaveview()
    vim.cmd [[keeppatterns %s/\s\+$//e]]
    vim.fn.winrestview(view)
  end,
})

-- Remember the colorscheme across restarts. Stored outside the repo, per machine.
local default_colorscheme = 'everforest'
local colorscheme_file = vim.fn.stdpath 'state' .. '/colorscheme'

local function saved_colorscheme()
  local ok, lines = pcall(vim.fn.readfile, colorscheme_file)
  return ok and lines[1] or default_colorscheme
end

vim.api.nvim_create_autocmd('ColorScheme', {
  desc = 'Save the selected colorscheme',
  group = augroup,
  callback = function(args)
    pcall(vim.fn.writefile, { args.match }, colorscheme_file)
  end,
})

-- [[ Diagnostics ]]
vim.diagnostic.config {
  severity_sort = true,
  float = { border = 'rounded', source = 'if_many' },
  underline = { severity = vim.diagnostic.severity.ERROR },
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = '󰅚 ',
      [vim.diagnostic.severity.WARN] = '󰀪 ',
      [vim.diagnostic.severity.INFO] = '󰋽 ',
      [vim.diagnostic.severity.HINT] = '󰌶 ',
    },
  },
  virtual_text = { source = 'if_many', spacing = 2 },
}

-- [[ Python virtualenv detection (uv) ]]
-- Priority: activated $VIRTUAL_ENV, then <project root>/.venv, else system python.
local function python_path(root_dir)
  if vim.env.VIRTUAL_ENV then
    return vim.env.VIRTUAL_ENV .. '/bin/python'
  end
  local venv_python = (root_dir or vim.fn.getcwd()) .. '/.venv/bin/python'
  if vim.fn.executable(venv_python) == 1 then
    return venv_python
  end
end

-- [[ Install lazy.nvim ]]
local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not vim.uv.fs_stat(lazypath) then
  local lazyrepo = 'https://github.com/folke/lazy.nvim.git'
  local out = vim.fn.system { 'git', 'clone', '--filter=blob:none', '--branch=stable', lazyrepo, lazypath }
  if vim.v.shell_error ~= 0 then
    error('Error cloning lazy.nvim:\n' .. out)
  end
end
vim.opt.rtp:prepend(lazypath)

-- [[ Plugins ]]
-- lazy.nvim can only be set up once; when reloading with <leader>R stop here
if vim.g.lazy_did_setup then
  return
end

-- Every plugin is pinned with `commit` (same SHAs as lazy-lock.json), so `:Lazy update` can't move them.
-- To upgrade one, change its commit here and run `:Lazy sync`. A plugin mentioned in several places is pinned once.
require('lazy').setup {
  { 'folke/lazy.nvim', commit = '306a05526ada86a7b30af95c5cc81ffba93fef97' },
  { 'tpope/vim-sleuth', commit = 'be69bff86754b1aa5adcbb527d7fcd1635a84080' }, -- Detect tabstop and shiftwidth automatically

  -- Colorschemes: the active one is applied at the end of this file (see [[ Colorscheme ]])
  {
    'sainnhe/everforest',
    commit = '85a86eb62409e3ec88713bff3d1b9d7374e112e4',
    priority = 1000,
    init = function()
      vim.g.everforest_background = 'medium' -- 'hard' | 'medium' | 'soft'
      vim.g.everforest_enable_italic = 1
      vim.g.everforest_better_performance = 1
    end,
  },
  {
    'ellisonleao/gruvbox.nvim',
    commit = '154eb5ff5b96d0641307113fa385eaf0d36d9796',
    priority = 1000,
    opts = {},
  },

  { -- Pending keybinds popup
    'folke/which-key.nvim',
    commit = '3aab2147e74890957785941f0c1ad87d0a44c15a',
    event = 'VimEnter',
    opts = {
      spec = {
        { '<leader>a', group = '[A]I / Claude' },
        { '<leader>b', group = '[B]uffer' },
        { '<leader>c', group = '[C]ode', mode = { 'n', 'x' } },
        { '<leader>d', group = '[D]iagnostics / Document' },
        { '<leader>g', group = '[G]it', mode = { 'n', 'v' } },
        { '<leader>r', group = '[R]ename' },
        { '<leader>s', group = '[S]earch' },
        { '<leader>t', group = '[T]oggle' },
        { '<leader>w', group = '[W]orkspace' },
        { '<leader>x', group = 'Trouble lists' },
      },
    },
  },

  { -- Git signs in the gutter + hunk actions
    'lewis6991/gitsigns.nvim',
    commit = 'd4854fa9a94b5c8b37dd209fb4a19e98e764186f',
    opts = {
      signs = {
        add = { text = '+' },
        change = { text = '~' },
        delete = { text = '_' },
        topdelete = { text = '‾' },
        changedelete = { text = '~' },
      },
      current_line_blame = true,
      current_line_blame_opts = {
        virt_text = true,
        virt_text_pos = 'eol',
        delay = 1000,
        ignore_whitespace = false,
      },
      on_attach = function(bufnr)
        local gs = require 'gitsigns'
        local function bmap(mode, lhs, rhs, desc)
          vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
        end
        bmap('n', ']c', function()
          if vim.wo.diff then
            vim.cmd.normal { ']c', bang = true }
          else
            gs.nav_hunk 'next'
          end
        end, 'Next git change')
        bmap('n', '[c', function()
          if vim.wo.diff then
            vim.cmd.normal { '[c', bang = true }
          else
            gs.nav_hunk 'prev'
          end
        end, 'Previous git change')
        bmap('n', '<leader>gs', gs.stage_hunk, '[G]it [S]tage/unstage hunk')
        bmap('v', '<leader>gs', function()
          gs.stage_hunk { vim.fn.line '.', vim.fn.line 'v' }
        end, '[G]it [S]tage/unstage hunk')
        bmap('n', '<leader>gr', gs.reset_hunk, '[G]it [R]eset hunk')
        bmap('v', '<leader>gr', function()
          gs.reset_hunk { vim.fn.line '.', vim.fn.line 'v' }
        end, '[G]it [R]eset hunk')
        bmap('n', '<leader>gp', gs.preview_hunk, '[G]it [P]review hunk')
        bmap('n', '<leader>gb', gs.blame_line, '[G]it [B]lame line')
        bmap('n', '<leader>gd', gs.diffthis, '[G]it [D]iff against index')
        bmap('n', '<leader>tb', gs.toggle_current_line_blame, '[T]oggle git [B]lame line')
      end,
    },
  },

  { -- Git diffs, file history, merge conflicts
    'sindrets/diffview.nvim',
    commit = '4516612fe98ff56ae0415a259ff6361a89419b0a',
    cmd = { 'DiffviewOpen', 'DiffviewClose', 'DiffviewFileHistory' },
    keys = {
      {
        '<leader>gv',
        function()
          if require('diffview.lib').get_current_view() then
            vim.cmd 'DiffviewClose'
          else
            vim.cmd 'DiffviewOpen'
          end
        end,
        desc = '[G]it diff [V]iew (toggle)',
      },
      { '<leader>gh', '<cmd>DiffviewFileHistory %<CR>', desc = '[G]it file [H]istory' },
      { '<leader>gH', '<cmd>DiffviewFileHistory<CR>', desc = '[G]it repo [H]istory' },
    },
    opts = {
      keymaps = {
        view = { { 'n', 'q', '<cmd>DiffviewClose<CR>', { desc = 'Close diffview' } } },
        file_panel = { { 'n', 'q', '<cmd>DiffviewClose<CR>', { desc = 'Close diffview' } } },
        file_history_panel = { { 'n', 'q', '<cmd>DiffviewClose<CR>', { desc = 'Close diffview' } } },
      },
    },
  },

  { -- Fuzzy finder
    'nvim-telescope/telescope.nvim',
    commit = '40aedd8a68c78a656a10a8d62d80c54af59420fb',
    event = 'VimEnter',
    dependencies = {
      { 'nvim-lua/plenary.nvim', commit = '74b06c6c75e4eeb3108ec01852001636d85a932b' },
      {
        'nvim-telescope/telescope-fzf-native.nvim',
        commit = 'b25b749b9db64d375d782094e2b9dce53ad53a40',
        build = 'make',
        cond = function()
          return vim.fn.executable 'make' == 1
        end,
      },
      { 'nvim-telescope/telescope-ui-select.nvim', commit = '6e51d7da30bd139a6950adf2a47fda6df9fa06d2' },
      { 'nvim-tree/nvim-web-devicons', commit = 'ec309a0eaff6ea967e58c275996155ab5c16938d' },
    },
    config = function()
      local actions = require 'telescope.actions'
      require('telescope').setup {
        defaults = {
          file_ignore_patterns = {
            '^%.git/',
            '%.venv/',
            '__pycache__',
            'node_modules',
            'package%-lock%.json',
          },
          mappings = {
            i = {
              ['<C-n>'] = actions.cycle_history_next,
              ['<C-p>'] = actions.cycle_history_prev,
              ['<C-j>'] = actions.move_selection_next,
              ['<C-k>'] = actions.move_selection_previous,
              ['<C-c>'] = actions.close,
            },
          },
        },
        pickers = {
          find_files = { hidden = true },
        },
        extensions = {
          ['ui-select'] = { require('telescope.themes').get_dropdown() },
        },
      }
      pcall(require('telescope').load_extension, 'fzf')
      pcall(require('telescope').load_extension, 'ui-select')

      local builtin = require 'telescope.builtin'
      map('n', '<leader>sh', builtin.help_tags, { desc = '[S]earch [H]elp' })
      map('n', '<leader>sk', builtin.keymaps, { desc = '[S]earch [K]eymaps' })
      map('n', '<leader>sf', builtin.find_files, { desc = '[S]earch [F]iles' })
      map('n', '<leader>sF', function()
        builtin.find_files { no_ignore = true, prompt_title = 'Find Files (incl. ignored)' }
      end, { desc = '[S]earch all [F]iles (incl. ignored)' })
      map('n', '<leader>ss', builtin.builtin, { desc = '[S]earch [S]elect Telescope' })
      map('n', '<leader>sw', builtin.grep_string, { desc = '[S]earch current [W]ord' })
      map('n', '<leader>sg', builtin.live_grep, { desc = '[S]earch by [G]rep' })
      map('n', '<leader>sd', builtin.diagnostics, { desc = '[S]earch [D]iagnostics' })
      map('n', '<leader>sr', builtin.resume, { desc = '[S]earch [R]esume' })
      map('n', '<leader>s.', builtin.oldfiles, { desc = '[S]earch Recent Files' })
      map('n', '<leader><leader>', builtin.buffers, { desc = '[ ] Find existing buffers' })
      map('n', '<leader>/', function()
        builtin.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown { winblend = 10, previewer = false })
      end, { desc = '[/] Fuzzily search in current buffer' })
      map('n', '<leader>s/', function()
        builtin.live_grep { grep_open_files = true, prompt_title = 'Live Grep in Open Files' }
      end, { desc = '[S]earch [/] in Open Files' })
      map('n', '<leader>sn', function()
        builtin.find_files { cwd = vim.fn.stdpath 'config' }
      end, { desc = '[S]earch [N]eovim files' })
      map('n', '<leader>sc', function()
        builtin.colorscheme { enable_preview = true, ignore_builtins = true }
      end, { desc = '[S]earch [C]olorscheme (live preview)' })
    end,
  },

  { -- Buffer tabs
    'akinsho/bufferline.nvim',
    commit = '655133c3b4c3e5e05ec549b9f8cc2894ac6f51b3',
    version = '*',
    dependencies = 'nvim-tree/nvim-web-devicons',
    opts = {
      options = {
        close_command = function(n)
          require('mini.bufremove').delete(n, false)
        end,
        right_mouse_command = function(n)
          require('mini.bufremove').delete(n, false)
        end,
        indicator = { icon = '▎' },
        modified_icon = '●',
        max_name_length = 30,
        max_prefix_length = 30,
        tab_size = 21,
        diagnostics = false,
        offsets = { { filetype = 'neo-tree', text = 'File Explorer', padding = 1 } },
        show_buffer_close_icons = true,
        show_close_icon = true,
        show_tab_indicators = true,
        persist_buffer_sort = true,
        separator_style = 'thin',
        enforce_regular_tabs = true,
        always_show_bufferline = true,
      },
    },
  },

  { -- File explorer
    'nvim-neo-tree/neo-tree.nvim',
    commit = '1a14083046d96e88e361d1da00761c40d45012f3',
    branch = 'v3.x',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-tree/nvim-web-devicons',
      { 'MunifTanjim/nui.nvim', commit = '10fc361835c856ba4233ef5ea135b919bf3dce97' },
      { 's1n7ax/nvim-window-picker', name = 'window-picker', commit = '6382540b2ae5de6c793d4aa2e3fe6dbb518505ec', version = '2.*', opts = {} }, -- used by `w` in the tree
    },
    keys = {
      { '<leader>e', '<cmd>Neotree toggle<CR>', desc = '[E]xplore' },
    },
    opts = {
      popup_border_style = 'rounded',
      enable_git_status = true,
      enable_diagnostics = true,
      window = { position = 'left', width = 40 },
      filesystem = {
        filtered_items = { hide_dotfiles = true, hide_gitignored = true }, -- `H` toggles hidden files
        hijack_netrw_behavior = 'open_default',
      },
      buffers = { follow_current_file = { enabled = true } },
    },
  },

  -- [[ LSP ]]
  { -- Lua LSP for Neovim config/runtime/plugins
    'folke/lazydev.nvim',
    commit = 'ff2cbcba459b637ec3fd165a2be59b7bbaeedf0d',
    ft = 'lua',
    opts = {
      library = {
        { path = '${3rd}/luv/library', words = { 'vim%.uv' } },
      },
    },
  },
  {
    'neovim/nvim-lspconfig',
    commit = '77b7432d4770d23b277d37923e5a08a442d8bb07',
    dependencies = {
      { 'mason-org/mason.nvim', commit = '2a6940af80375532e5e9e7c1f2fc6319a1b7a69d', opts = {} },
      { 'mason-org/mason-lspconfig.nvim', commit = 'a338f44149f5673882c32629697d67b0c0547aec' },
      { 'WhoIsSethDaniel/mason-tool-installer.nvim', commit = '443f1ef8b5e6bf47045cb2217b6f748a223cf7dc' },
      { 'j-hui/fidget.nvim', commit = '9e0201673e08e997e7cf52afca5565c70bd117f3', opts = {} },
      'saghen/blink.cmp', -- registers its completion capabilities with every server
    },
    config = function()
      vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('user-lsp-attach', { clear = true }),
        callback = function(event)
          local function lmap(keys, func, desc, mode)
            vim.keymap.set(mode or 'n', keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
          end
          local builtin = require 'telescope.builtin'

          lmap('gd', builtin.lsp_definitions, '[G]oto [D]efinition')
          lmap('gr', builtin.lsp_references, '[G]oto [R]eferences')
          lmap('gI', builtin.lsp_implementations, '[G]oto [I]mplementation')
          lmap('gD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')
          lmap('<leader>D', builtin.lsp_type_definitions, 'Type [D]efinition')
          lmap('<leader>ds', builtin.lsp_document_symbols, '[D]ocument [S]ymbols')
          lmap('<leader>ws', builtin.lsp_dynamic_workspace_symbols, '[W]orkspace [S]ymbols')
          lmap('<leader>rn', vim.lsp.buf.rename, '[R]e[n]ame')
          lmap('<leader>ca', vim.lsp.buf.code_action, '[C]ode [A]ction', { 'n', 'x' })
          lmap('K', function()
            vim.lsp.buf.hover {
              border = 'rounded',
              max_width = 100,
              max_height = 30,
              -- defaults + BufHidden, so the float also closes on <S-h>/<S-l> buffer switches
              close_events = { 'CursorMoved', 'CursorMovedI', 'InsertCharPre', 'BufHidden' },
            }
          end, 'Hover documentation')

          local client = vim.lsp.get_client_by_id(event.data.client_id)
          if not client then
            return
          end

          -- Let basedpyright provide hover docs instead of ruff
          if client.name == 'ruff' then
            client.server_capabilities.hoverProvider = false
          end

          -- Highlight references of the word under the cursor
          if client:supports_method('textDocument/documentHighlight', event.buf) then
            local hl_group = vim.api.nvim_create_augroup('user-lsp-highlight', { clear = false })
            vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
              buffer = event.buf,
              group = hl_group,
              callback = vim.lsp.buf.document_highlight,
            })
            vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
              buffer = event.buf,
              group = hl_group,
              callback = vim.lsp.buf.clear_references,
            })
            vim.api.nvim_create_autocmd('LspDetach', {
              group = vim.api.nvim_create_augroup('user-lsp-detach', { clear = true }),
              callback = function(event2)
                vim.lsp.buf.clear_references()
                vim.api.nvim_clear_autocmds { group = 'user-lsp-highlight', buffer = event2.buf }
              end,
            })
          end

          if client:supports_method('textDocument/inlayHint', event.buf) then
            lmap('<leader>th', function()
              vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf })
            end, '[T]oggle Inlay [H]ints')
          end
        end,
      })

      -- Only these servers are enabled (anything else installed in Mason stays off).
      ---@type table<string, vim.lsp.Config>
      local servers = {
        basedpyright = {
          settings = {
            basedpyright = {
              disableOrganizeImports = true, -- ruff handles imports
              analysis = { typeCheckingMode = 'standard' },
            },
          },
          -- Point the server at the project's uv virtualenv
          before_init = function(_, config)
            local py = python_path(config.root_dir)
            if py then
              -- mutate in place: the client already holds a reference to this table
              config.settings.python = config.settings.python or {}
              config.settings.python.pythonPath = py
            end
          end,
        },
        ruff = {}, -- linting, formatting, import sorting
        rust_analyzer = {}, -- formats with rustfmt via <leader>f
        ts_ls = {}, -- JavaScript + TypeScript (incl. jsx/tsx)
        terraformls = {}, -- formats with `terraform fmt` via <leader>f
        tflint = {}, -- Terraform linting
        gopls = {},
        bashls = {},
        yamlls = {},
        lua_ls = {
          settings = {
            Lua = { completion = { callSnippet = 'Replace' } },
          },
        },
      }

      for name, config in pairs(servers) do
        vim.lsp.config(name, config)
      end

      local ensure_installed = vim.tbl_keys(servers)
      vim.list_extend(ensure_installed, { 'stylua' })
      require('mason-tool-installer').setup { ensure_installed = ensure_installed }

      require('mason-lspconfig').setup {
        ensure_installed = {},
        automatic_enable = vim.tbl_keys(servers),
      }
    end,
  },

  { -- Formatting
    'stevearc/conform.nvim',
    commit = '016802de402556da54c36bd7359b441266b01cdd',
    event = 'BufWritePre',
    cmd = 'ConformInfo',
    keys = {
      {
        '<leader>f',
        function()
          require('conform').format { async = true, lsp_format = 'fallback' }
        end,
        mode = '',
        desc = '[F]ormat buffer',
      },
    },
    opts = {
      notify_on_error = false,
      formatters_by_ft = {
        lua = { 'stylua' },
        python = { 'ruff_organize_imports', 'ruff_format' },
      },
    },
  },

  { -- Diagnostics, references, symbols and quickfix in a list
    'folke/trouble.nvim',
    commit = 'bd67efe408d4816e25e8491cc5ad4088e708a69a',
    cmd = 'Trouble',
    opts = {},
    keys = {
      { '<leader>xx', '<cmd>Trouble diagnostics toggle<CR>', desc = 'Diagnostics (project)' },
      { '<leader>xb', '<cmd>Trouble diagnostics toggle filter.buf=0<CR>', desc = 'Diagnostics ([B]uffer)' },
      { '<leader>xs', '<cmd>Trouble symbols toggle focus=false<CR>', desc = '[S]ymbols outline' },
      {
        '<leader>xr',
        '<cmd>Trouble lsp toggle focus=false win.position=right<CR>',
        desc = 'LSP definitions / [R]eferences',
      },
      { '<leader>xq', '<cmd>Trouble qflist toggle<CR>', desc = '[Q]uickfix list' },
      { '<leader>xl', '<cmd>Trouble loclist toggle<CR>', desc = '[L]ocation list' },
    },
  },

  -- [[ Completion ]]
  { -- Copilot (suggestions are shown through blink.cmp, not inline)
    'zbirenbaum/copilot.lua',
    commit = '891bb2fda9595307e762cead6a2b7dc2f4076c37',
    cmd = 'Copilot',
    event = 'InsertEnter',
    opts = {
      panel = { enabled = false },
      suggestion = { enabled = false },
      filetypes = {
        yaml = false,
        markdown = false,
        help = false,
        gitcommit = false,
        gitrebase = false,
        hgcommit = false,
        svn = false,
        cvs = false,
        ['.'] = false,
      },
      copilot_node_command = 'node',
    },
  },
  {
    'saghen/blink.cmp',
    commit = '78336bc89ee5365633bcf754d93df01678b5c08f',
    event = 'VimEnter',
    version = '1.*',
    dependencies = {
      { 'rafamadriz/friendly-snippets', commit = 'b4d01b0fdf3c9a549961c2f9ffe8dc09be166219' },
      { 'fang2hou/blink-copilot', commit = '7ad8209b2f880a2840c94cdcd80ab4dc511d4f39', dependencies = 'zbirenbaum/copilot.lua' },
    },
    --- @module 'blink.cmp'
    --- @type blink.cmp.Config
    opts = {
      keymap = {
        preset = 'default', -- <C-y> accept, <C-n>/<C-p> select, <C-Space> open, <C-e> close, <C-b>/<C-f> scroll docs
        ['<C-j>'] = { 'select_next', 'fallback' },
        ['<C-k>'] = { 'select_prev', 'fallback' },
        ['<C-l>'] = { 'snippet_forward', 'fallback' },
        ['<C-h>'] = { 'snippet_backward', 'fallback' },
      },
      appearance = { nerd_font_variant = 'mono' },
      completion = {
        documentation = { auto_show = true, auto_show_delay_ms = 300 },
        list = { selection = { preselect = true, auto_insert = false } },
      },
      sources = {
        default = { 'lsp', 'path', 'snippets', 'copilot', 'lazydev' },
        providers = {
          lazydev = { module = 'lazydev.integrations.blink', score_offset = 100 },
          copilot = { name = 'Copilot', module = 'blink-copilot', score_offset = 50, async = true },
        },
      },
      signature = { enabled = true },
      fuzzy = { implementation = 'prefer_rust_with_warning' },
    },
  },

  { -- Auto-close brackets and quotes
    'windwp/nvim-autopairs',
    commit = '3172f40c16563db871a58f20d205c710ad782311',
    event = 'InsertEnter',
    opts = {},
  },

  -- [[ AI ]]
  {
    'codegik/claude-chat.nvim',
    commit = '3124c5fff1513c21bdc6c0f4a412785990da2986',
    cmd = { 'ClaudeChat', 'ClaudeChatReset', 'ClaudeChatFile', 'ClaudeChatContinue', 'ClaudeChatSessions' },
    keys = {
      { '<leader>ai', '<cmd>ClaudeChat<cr>', desc = 'Claude Chat: toggle sidebar' },
      { '<leader>af', '<cmd>ClaudeChatFile<cr>', desc = 'Claude Chat: add current file' },
    },
    opts = {},
  },

  -- [[ Editing / UI ]]
  { -- Highlight TODO, NOTE, etc. in comments
    'folke/todo-comments.nvim',
    commit = '31e3c38ce9b29781e4422fc0322eb0a21f4e8668',
    event = 'VimEnter',
    dependencies = 'nvim-lua/plenary.nvim',
    opts = { signs = false },
  },

  { -- Indentation guides
    'lukas-reineke/indent-blankline.nvim',
    commit = 'f1e186e44d3b7f9ae918008e2c28ce37c6023d2d',
    main = 'ibl',
    opts = {},
  },

  { -- Text objects, surround, statusline
    'echasnovski/mini.nvim',
    commit = 'ed8683521996657ce774e5eec9d2f9b1b5ecef82',
    config = function()
      require('mini.ai').setup { n_lines = 500 } -- va), yinq, ci'
      require('mini.surround').setup() -- saiw), sd', sr)'
      require('mini.bufremove').setup() -- close buffers, keep windows
      local statusline = require 'mini.statusline'
      statusline.setup { use_icons = vim.g.have_nerd_font }
      ---@diagnostic disable-next-line: duplicate-set-field
      statusline.section_location = function()
        return '%2l:%-2v'
      end
    end,
  },

  { -- Syntax highlighting / indentation
    'nvim-treesitter/nvim-treesitter',
    commit = 'cf12346a3414fa1b06af75c79faebe7f76df080a',
    branch = 'master', -- `main` is an incompatible rewrite
    build = ':TSUpdate',
    main = 'nvim-treesitter.configs',
    opts = {
      ensure_installed = {
        'bash',
        'c',
        'diff',
        'go',
        'hcl',
        'html',
        'javascript',
        'json',
        'lua',
        'luadoc',
        'markdown',
        'markdown_inline',
        'python',
        'query',
        'rust',
        'terraform',
        'toml',
        'tsx',
        'typescript',
        'vim',
        'vimdoc',
        'yaml',
      },
      auto_install = true,
      highlight = { enable = true },
      indent = { enable = true },
    },
  },
}

-- [[ Colorscheme ]]
-- Use the last one picked (saved by the ColorScheme autocmd above), else the default
local ok_cs = pcall(vim.cmd.colorscheme, saved_colorscheme())
if not ok_cs then
  vim.cmd.colorscheme(default_colorscheme)
end

-- vim: ts=2 sts=2 sw=2 et
