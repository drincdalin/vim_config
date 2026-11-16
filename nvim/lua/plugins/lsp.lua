return {
    {
        'hrsh7th/nvim-cmp',
        event = 'InsertEnter',
        dependencies = {
            'hrsh7th/cmp-nvim-lsp',
            'hrsh7th/cmp-buffer',
            'hrsh7th/cmp-path',
        },
        config = function()
            local cmp = require('cmp')
            cmp.setup({
                mapping = cmp.mapping.preset.insert({
                    ['<C-Space>'] = cmp.mapping.complete(),
                    ['<CR>'] = cmp.mapping.confirm({ select = true }),
                    ['<Tab>'] = cmp.mapping.select_next_item(),
                    ['<S-Tab>'] = cmp.mapping.select_prev_item(),
                }),
                sources = cmp.config.sources({
                    { name = 'nvim_lsp' },
                    { name = 'buffer' },
                    { name = 'path' },
                }),
            })
        end,
    },
    {
        'hrsh7th/cmp-nvim-lsp',
        event = { 'BufReadPre', 'BufNewFile' },
        dependencies = { 'hrsh7th/nvim-cmp' },
        config = function()
            local has_cmp, cmp_nvim_lsp = pcall(require, 'cmp_nvim_lsp')
            local capabilities = vim.tbl_deep_extend(
                'force',
                vim.lsp.protocol.make_client_capabilities(),
                has_cmp and cmp_nvim_lsp.default_capabilities() or {}
            )

            vim.lsp.config('*', {
                root_markers = { '.git' },
                capabilities = capabilities,
            })

            vim.diagnostic.config({
                virtual_text  = true,
                severity_sort = true,
                float         = {
                    style  = 'minimal',
                    border = 'rounded',
                    source = 'if_many',
                    header = '',
                    prefix = '',
                },
                signs         = {
                    text = {
                        [vim.diagnostic.severity.ERROR] = '✘',
                        [vim.diagnostic.severity.WARN]  = '▲',
                        [vim.diagnostic.severity.HINT]  = '⚑',
                        [vim.diagnostic.severity.INFO]  = '»',
                    },
                },
            })

            local orig = vim.lsp.util.open_floating_preview
            ---@diagnostic disable-next-line: duplicate-set-field
            function vim.lsp.util.open_floating_preview(contents, syntax, opts, ...)
                opts            = opts or {}
                opts.border     = opts.border or 'rounded'
                opts.max_width  = opts.max_width or 80
                opts.max_height = opts.max_height or 24
                opts.wrap       = opts.wrap ~= false
                return orig(contents, syntax, opts, ...)
            end

            vim.api.nvim_create_autocmd('LspAttach', {
                group = vim.api.nvim_create_augroup('my.lsp', {}),
                callback = function(args)
                    local client = assert(vim.lsp.get_client_by_id(args.data.client_id))
                    local buf    = args.buf
                    local map    = function(mode, lhs, rhs) vim.keymap.set(mode, lhs, rhs, { buffer = buf }) end

                    map('n', 'K', vim.lsp.buf.hover)
                    map('n', 'gd', vim.lsp.buf.definition)
                    map('n', 'gD', vim.lsp.buf.declaration)
                    map('n', 'gi', vim.lsp.buf.implementation)
                    map('n', 'go', vim.lsp.buf.type_definition)
                    map('n', 'gr', vim.lsp.buf.references)
                    map('n', 'gs', vim.lsp.buf.signature_help)
                    map('n', 'gl', vim.diagnostic.open_float)
                    map('n', '<F2>', vim.lsp.buf.rename)
                    map({ 'n', 'x' }, '<F3>', function() vim.lsp.buf.format({ async = true }) end)
                    map('n', '<F4>', vim.lsp.buf.code_action)

                    if client:supports_method('textDocument/documentHighlight') then
                        local highlight_augroup = vim.api.nvim_create_augroup('my.lsp.highlight', { clear = false })
                        vim.api.nvim_clear_autocmds({ group = highlight_augroup, buffer = buf })
                        vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
                            buffer = buf,
                            group = highlight_augroup,
                            callback = vim.lsp.buf.document_highlight,
                        })
                        vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
                            buffer = buf,
                            group = highlight_augroup,
                            callback = vim.lsp.buf.clear_references,
                        })
                    end

                    local excluded_filetypes = { php = true, c = true, cpp = true }
                    if not client:supports_method('textDocument/willSaveWaitUntil')
                        and client:supports_method('textDocument/formatting')
                        and not excluded_filetypes[vim.bo[buf].filetype]
                    then
                        local format_augroup = vim.api.nvim_create_augroup('my.lsp.format', { clear = false })
                        vim.api.nvim_clear_autocmds({ group = format_augroup, buffer = buf })
                        vim.api.nvim_create_autocmd('BufWritePre', {
                            group = format_augroup,
                            buffer = buf,
                            callback = function()
                                vim.lsp.buf.format({ bufnr = buf, id = client.id, timeout_ms = 1000 })
                            end,
                        })
                    end
                end,
            })

            vim.lsp.config['luals'] = {
                cmd = { 'lua-language-server' },
                filetypes = { 'lua' },
                root_markers = { { '.luarc.json', '.luarc.jsonc' }, '.git' },
                settings = {
                    Lua = {
                        runtime = { version = 'LuaJIT' },
                        diagnostics = { globals = { 'vim' } },
                        workspace = {
                            checkThirdParty = false,
                            library = vim.list_extend(
                                vim.api.nvim_get_runtime_file('', true),
                                { '/home/tony/repos/oxwm/templates' }
                            ),
                        },
                        telemetry = { enable = false },
                    },
                },
            }

            vim.lsp.config['cssls'] = {
                cmd = { 'vscode-css-language-server', '--stdio' },
                filetypes = { 'css', 'scss', 'less' },
                root_markers = { 'package.json', '.git' },
                settings = {
                    css = { validate = true },
                    scss = { validate = true },
                    less = { validate = true },
                },
            }

            vim.lsp.config['phpls'] = {
                cmd = { 'intelephense', '--stdio' },
                filetypes = { 'php' },
                root_markers = { 'composer.json', '.git' },
                settings = {
                    intelephense = {
                        files = {
                            maxSize = 5000000, -- default 5MB
                        },
                    },
                },
            }

            vim.lsp.config['ts_ls'] = {
                cmd = { 'typescript-language-server', '--stdio' },
                filetypes = {
                    'javascript', 'javascriptreact', 'javascript.jsx',
                    'typescript', 'typescriptreact', 'typescript.tsx',
                },
                root_markers = { 'package.json', 'tsconfig.json', 'jsconfig.json', '.git' },
                settings = {
                    completions = {
                        completeFunctionCalls = true,
                    },
                },
            }

            vim.lsp.config['zls'] = {
                cmd = { 'zls' },
                filetypes = { 'zig', 'zir' },
                root_markers = { 'zls.json', 'build.zig', '.git' },
                settings = {
                    zls = {
                        enable_build_on_save = true,
                        build_on_save_step = 'install',
                        warn_style = false,
                        enable_snippets = true,
                    },
                },
            }

            vim.lsp.config['nil_ls'] = {
                cmd = { 'nil' },
                filetypes = { 'nix' },
                root_markers = { 'flake.nix', 'default.nix', '.git' },
                settings = {
                    ['nil'] = {
                        formatting = {
                            command = { 'alejandra' },
                        },
                    },
                },
            }

            vim.lsp.config['rust_analyzer'] = {
                cmd = { 'rust-analyzer' },
                filetypes = { 'rust' },
                root_markers = { 'Cargo.toml', 'rust-project.json', '.git' },
                settings = {
                    ['rust-analyzer'] = {
                        cargo = { allFeatures = true },
                        formatting = {
                            command = { 'rustfmt' },
                        },
                    },
                },
            }

            -- C / C++ via clangd
            vim.lsp.config['clangd'] = {
                cmd = {
                    'clangd',
                    -- '--background-index',
                    -- '--clang-tidy',
                    -- '--header-insertion=never',
                    -- '--completion-style=detailed',
                    -- '--query-driver=/nix/store/*-gcc-*/bin/gcc*,/nix/store/*-clang-*/bin/clang*,/run/current-system/sw/bin/cc*',
                },
                filetypes = { 'c', 'cpp', 'objc', 'objcpp' },
                root_markers = { 'compile_commands.json', '.clangd', 'configure.ac', 'Makefile', '.git' },
                -- init_options = {
                --     fallbackFlags = { '-std=c23' }, -- Default to C23
                -- },
            }

            vim.lsp.config['c3lsp'] = {
                cmd = { 'c3-lsp' },
                filetypes = { 'c3' },
                root_markers = { 'project.json', '.git' },
            }

            vim.lsp.config['serve_d'] = {
                cmd = { 'serve-d' },
                filetypes = { 'd' },
                root_markers = { 'dub.sdl', 'dub.json', '.git' },
            }

            vim.lsp.config['jsonls'] = {
                cmd = { 'vscode-json-languageserver', '--stdio' },
                filetypes = { 'json', 'jsonc' },
                root_markers = { 'package.json', '.git', 'config.jsonc' },
            }

            vim.lsp.config['hls'] = {
                cmd = { 'haskell-language-server-wrapper', '--lsp' },
                filetypes = { 'haskell', 'lhaskell' },
                root_markers = { 'stack.yaml', 'cabal.project', 'package.yaml', '*.cabal', 'hie.yaml', '.git' },
                settings = {
                    haskell = {
                        formattingProvider = 'fourmolu',
                        plugin = {
                            semanticTokens = { globalOn = false },
                        },
                    },
                },
            }

            vim.lsp.config['gopls'] = {
                cmd = { 'gopls' },
                filetypes = { 'go', 'gomod', 'gowork', 'gotmpl' },
                root_markers = { 'go.mod', 'go.work', '.git' },
                settings = {
                    gopls = {
                        analyses = {
                            unusedparams = false,
                            ST1003 = false,
                            ST1000 = false,
                        },
                        staticcheck = true,
                    },
                },
            }

            vim.lsp.config['templ'] = {
                cmd = { 'templ', 'lsp' },
                filetypes = { 'templ' },
                root_markers = { 'go.mod', '.git' },
            }

            vim.filetype.add({
                extension = {
                    c3 = 'c3',
                    d = 'd',
                    templ = 'templ',
                },
            })

            local servers = {
                'luals',
                'cssls',
                'phpls',
                'ts_ls',
                'zls',
                'nil_ls',
                'rust_analyzer',
                'clangd',
                'c3lsp',
                'serve_d',
                'jsonls',
                'hls',
                'gopls',
                'templ',
            }

            vim.lsp.enable(servers)
        end,
    },
}

