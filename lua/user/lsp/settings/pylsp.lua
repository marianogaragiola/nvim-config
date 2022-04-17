-- require"lspconfig".pylsp.setup {
--     filetypes = {"python"},
--     settings = {
--         configurationSources = {"flake8"},
--     formatCommand = {"black"}
--     }
-- }
local opts = {
    setup = {
        enable = true,
        cmd = cmd,
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