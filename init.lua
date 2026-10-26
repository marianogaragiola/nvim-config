-- Neovim config (Neovim 0.11+, lazy.nvim)
-- Previous kickstart-based config is backed up in init-back.lua

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
map('n', '<leader>bc', '<cmd>bp|bd #<CR>', { desc = '[B]uffer [C]lose' })

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

require('lazy').setup {
  'tpope/vim-sleuth', -- Detect tabstop and shiftwidth automatically

  { -- Colorscheme
    'ellisonleao/gruvbox.nvim',
    priority = 1000,
    config = function()
      require('gruvbox').setup {}
      vim.cmd.colorscheme 'gruvbox'
    end,
  },

  { -- Pending keybinds popup
    'folke/which-key.nvim',
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
      },
    },
  },

  { -- Git signs in the gutter + hunk actions
    'lewis6991/gitsigns.nvim',
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

  { -- Fuzzy finder
    'nvim-telescope/telescope.nvim',
    event = 'VimEnter',
    dependencies = {
      'nvim-lua/plenary.nvim',
      {
        'nvim-telescope/telescope-fzf-native.nvim',
        build = 'make',
        cond = function()
          return vim.fn.executable 'make' == 1
        end,
      },
      'nvim-telescope/telescope-ui-select.nvim',
      'nvim-tree/nvim-web-devicons',
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
          find_files = { hidden = true, no_ignore = true },
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
    end,
  },

  { -- Buffer tabs
    'akinsho/bufferline.nvim',
    version = '*',
    dependencies = 'nvim-tree/nvim-web-devicons',
    opts = {
      options = {
        close_command = 'bdelete! %d',
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
    branch = 'v3.x',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-tree/nvim-web-devicons',
      'MunifTanjim/nui.nvim',
      { 's1n7ax/nvim-window-picker', name = 'window-picker', version = '2.*', opts = {} }, -- used by `w` in the tree
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
    ft = 'lua',
    opts = {
      library = {
        { path = '${3rd}/luv/library', words = { 'vim%.uv' } },
      },
    },
  },
  {
    'neovim/nvim-lspconfig',
    dependencies = {
      { 'mason-org/mason.nvim', opts = {} },
      'mason-org/mason-lspconfig.nvim',
      'WhoIsSethDaniel/mason-tool-installer.nvim',
      { 'j-hui/fidget.nvim', opts = {} },
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

  -- [[ Completion ]]
  { -- Copilot (suggestions are shown through blink.cmp, not inline)
    'zbirenbaum/copilot.lua',
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
    event = 'VimEnter',
    version = '1.*',
    dependencies = {
      'rafamadriz/friendly-snippets',
      { 'fang2hou/blink-copilot', dependencies = 'zbirenbaum/copilot.lua' },
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
    event = 'InsertEnter',
    opts = {},
  },

  -- [[ AI ]]
  {
    'codegik/claude-chat.nvim',
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
    event = 'VimEnter',
    dependencies = 'nvim-lua/plenary.nvim',
    opts = { signs = false },
  },

  { -- Indentation guides
    'lukas-reineke/indent-blankline.nvim',
    main = 'ibl',
    opts = {},
  },

  { -- Text objects, surround, statusline
    'echasnovski/mini.nvim',
    config = function()
      require('mini.ai').setup { n_lines = 500 } -- va), yinq, ci'
      require('mini.surround').setup() -- saiw), sd', sr)'
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

-- vim: ts=2 sts=2 sw=2 et
