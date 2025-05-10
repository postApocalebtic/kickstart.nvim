-- ~/.config/nvim/init.lua

-- Install packer.nvim automatically if it's not installed
local install_path = vim.fn.stdpath 'data' .. '/site/pack/packer/start/packer.nvim'
if vim.fn.empty(vim.fn.glob(install_path)) > 0 then
  vim.fn.system { 'git', 'clone', '--depth', '1', 'https://github.com/wbthomason/packer.nvim', install_path }
  vim.cmd [[packadd packer.nvim]]
end

-- Plugin installation
require('packer').startup(function(use)
  -- Plugin manager
  use 'wbthomason/packer.nvim'

  -- LSP Configuration & Plugins
  use {
    'neovim/nvim-lspconfig',
    requires = {
      -- Automatically install LSPs to stdpath for neovim
      'williamboman/mason.nvim',
      'williamboman/mason-lspconfig.nvim',

      -- Additional lua configuration for neovim
      'folke/neodev.nvim',
    },
  }

  -- Autocompletion
  use {
    'hrsh7th/nvim-cmp',
    requires = {
      'hrsh7th/cmp-nvim-lsp',
      'hrsh7th/cmp-buffer',
      'hrsh7th/cmp-path',
      'L3MON4D3/LuaSnip',
      'saadparwaiz1/cmp_luasnip',
    },
  }
end)

-- General Neovim settings
vim.opt.number = true -- Show line numbers
vim.opt.relativenumber = true -- Show relative line numbers
vim.opt.wrap = false -- Disable line wrap
vim.opt.expandtab = true -- Use spaces instead of tabs
vim.opt.tabstop = 2 -- Number of spaces tabs count for
vim.opt.shiftwidth = 2 -- Size of an indent
vim.opt.smartindent = true -- Insert indents automatically

-- Set up LSP configurations
require 'lsp-config'

-- ~/.config/nvim/lua/lsp-config.lua

-- Setup Mason
require('mason').setup {
  ui = {
    icons = {
      package_installed = '✓',
      package_pending = '➜',
      package_uninstalled = '✗',
    },
  },
}

-- Setup neodev for better Lua LSP configuration
require('neodev').setup()

-- Setup Mason-lspconfig
require('mason-lspconfig').setup {
  -- List of servers to automatically install
  ensure_installed = {
    'tsserver', -- TypeScript/JavaScript
    'volar', -- Vue
    'tailwindcss', -- Tailwind CSS
    'eslint', -- ESLint
    'cssls', -- CSS
    'html', -- HTML
    'jsonls', -- JSON
    'emmet_ls', -- Emmet
    'lua_ls', -- Lua
  },
  automatic_installation = true,
}

-- nvim-cmp setup
local cmp = require 'cmp'
local luasnip = require 'luasnip'

cmp.setup {
  snippet = {
    expand = function(args)
      luasnip.lsp_expand(args.body)
    end,
  },
  mapping = cmp.mapping.preset.insert {
    ['<C-d>'] = cmp.mapping.scroll_docs(-4),
    ['<C-f>'] = cmp.mapping.scroll_docs(4),
    ['<C-Space>'] = cmp.mapping.complete(),
    ['<CR>'] = cmp.mapping.confirm {
      behavior = cmp.ConfirmBehavior.Replace,
      select = true,
    },
    ['<Tab>'] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_next_item()
      elseif luasnip.expand_or_jumpable() then
        luasnip.expand_or_jump()
      else
        fallback()
      end
    end, { 'i', 's' }),
    ['<S-Tab>'] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_prev_item()
      elseif luasnip.jumpable(-1) then
        luasnip.jump(-1)
      else
        fallback()
      end
    end, { 'i', 's' }),
  },
  sources = {
    { name = 'nvim_lsp' },
    { name = 'luasnip' },
    { name = 'buffer' },
    { name = 'path' },
  },
}

-- LSP settings
local lspconfig = require 'lspconfig'
local mason_registry = require 'mason-registry'

-- Use an on_attach function to set keymaps after the LSP attaches to a buffer
local on_attach = function(client, bufnr)
  -- LSP Keybindings
  local opts = { noremap = true, silent = true, buffer = bufnr }
  vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)
  vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
  vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
  vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
  vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, opts)
  vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, opts)
  vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, opts)
  vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
  vim.keymap.set('n', '<leader>f', function()
    vim.lsp.buf.format { async = true }
  end, opts)
end

-- Setup capabilities with nvim-cmp
local capabilities = require('cmp_nvim_lsp').default_capabilities()

-- TypeScript Server setup (works for React)
lspconfig.tsserver.setup {
  on_attach = on_attach,
  capabilities = capabilities,
  filetypes = { 'typescript', 'javascript', 'javascriptreact', 'typescriptreact', 'javascript.jsx', 'typescript.tsx' },
  root_dir = lspconfig.util.root_pattern('package.json', 'tsconfig.json', 'jsconfig.json', '.git'),
}

-- Vue Server setup (Volar for Vue 3)
-- Get the Vue language server path for TypeScript integration
local function get_vue_ts_plugin_path()
  if mason_registry.is_installed 'vue-language-server' then
    local vue_ls_path = mason_registry.get_package('vue-language-server'):get_install_path()
    return vue_ls_path .. '/node_modules/@vue/language-server/node_modules/@vue/typescript-plugin'
  end
  return nil
end

local vue_ts_plugin_path = get_vue_ts_plugin_path()

-- Volar setup
lspconfig.volar.setup {
  on_attach = on_attach,
  capabilities = capabilities,
  filetypes = { 'vue' },
  root_dir = lspconfig.util.root_pattern('package.json', 'vue.config.js', '.git'),
}

-- TypeScript plugin for Vue
if vue_ts_plugin_path then
  lspconfig.tsserver.setup {
    on_attach = on_attach,
    capabilities = capabilities,
    filetypes = { 'typescript', 'javascript', 'javascriptreact', 'typescriptreact', 'vue' },
    init_options = {
      plugins = {
        {
          name = '@vue/typescript-plugin',
          location = vue_ts_plugin_path,
          languages = { 'vue' },
        },
      },
    },
  }
end

-- Nuxt setup (uses Volar with additional capabilities)
-- For Nuxt, it mostly relies on the Vue language server with specific nuxt-aware configurations
if lspconfig.volar then
  lspconfig.volar.setup {
    on_attach = on_attach,
    capabilities = capabilities,
    filetypes = { 'vue', 'typescript', 'javascript' },
    root_dir = lspconfig.util.root_pattern('nuxt.config.js', 'nuxt.config.ts', '.nuxt'),
    init_options = {
      typescript = {
        tsdk = vim.fn.expand '$HOME/.local/share/nvim/mason/packages/typescript-language-server/node_modules/typescript/lib',
      },
    },
  }
end

-- Next.js setup (uses TypeScript server with Next.js specific configuration)
lspconfig.tsserver.setup {
  on_attach = on_attach,
  capabilities = capabilities,
  filetypes = { 'typescript', 'javascript', 'typescriptreact', 'javascriptreact' },
  root_dir = lspconfig.util.root_pattern('next.config.js', 'next.config.ts', '.git'),
}

-- Tailwind CSS setup
lspconfig.tailwindcss.setup {
  on_attach = on_attach,
  capabilities = capabilities,
  filetypes = {
    'html',
    'css',
    'scss',
    'javascript',
    'javascriptreact',
    'typescript',
    'typescriptreact',
    'vue',
    'svelte',
  },
  root_dir = lspconfig.util.root_pattern(
    'tailwind.config.js',
    'tailwind.config.cjs',
    'tailwind.config.ts',
    'postcss.config.js',
    'postcss.config.cjs',
    'postcss.config.ts'
  ),
}

-- HTML setup
lspconfig.html.setup {
  on_attach = on_attach,
  capabilities = capabilities,
}

-- CSS setup
lspconfig.cssls.setup {
  on_attach = on_attach,
  capabilities = capabilities,
}

-- Emmet setup (useful for all the frameworks)
lspconfig.emmet_ls.setup {
  on_attach = on_attach,
  capabilities = capabilities,
  filetypes = {
    'html',
    'css',
    'scss',
    'javascript',
    'javascriptreact',
    'typescript',
    'typescriptreact',
    'vue',
    'svelte',
  },
}

-- ESLint setup
lspconfig.eslint.setup {
  on_attach = function(client, bufnr)
    on_attach(client, bufnr)
    -- Auto-fix on save
    vim.api.nvim_create_autocmd('BufWritePre', {
      buffer = bufnr,
      command = 'EslintFixAll',
    })
  end,
  capabilities = capabilities,
}

-- Lua setup for Neovim configuration
lspconfig.lua_ls.setup {
  on_attach = on_attach,
  capabilities = capabilities,
  settings = {
    Lua = {
      runtime = {
        version = 'LuaJIT',
      },
      diagnostics = {
        globals = { 'vim' },
      },
      workspace = {
        library = vim.api.nvim_get_runtime_file('', true),
        checkThirdParty = false,
      },
      telemetry = {
        enable = false,
      },
    },
  },
}
