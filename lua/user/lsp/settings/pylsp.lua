-- require"lspconfig".pylsp.setup {
--     filetypes = {"python"},
--     settings = {
--         configurationSources = {"flake8"},
--     formatCommand = {"black"}
--     }
-- }
-- nvim_lsp.pyls.setup {
--     cmd = {"pyls"},
--     cmd_env = {VIRTUAL_ENV = "$HOME/.envs/base"}
-- }
local opts = {
    setup = {
        enable = true,
        cmd = cmd,
        cmd_env = {
            VIRTUAL_ENV = "$HOME/.envs/base"
        },
        on_attach = on_attach,
        settings = {
            pylsp = {
                plugings = {
                    configurationSources = {"flake8", "black"},
                    flake8 = { enabled = false},
                    pycodestyle = {enabled = false},
                    pyflakes = {enabled=false},
                    black = {enabled=false},
                },
            },
            formatCommand = {"black"}
        },
    }
    -- setup = {
    --     filetypes = {"python"},
    --     settings = {
    --         configurationSources = {"flake8", "isort"},
    --         formatCommand = {"black"}
    --     }
    -- }
}
return opts