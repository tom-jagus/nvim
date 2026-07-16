-- ┌─────────────────────────┐
-- │ Plugins outside of MINI │
-- └─────────────────────────┘
--
-- This file contains installation and configuration of plugins outside of MINI.
-- They significantly improve user experience in a way not yet possible with MINI.
-- These are mostly plugins that provide programming language specific behavior.
--
-- Use this file to install and configure other such plugins.

-- Make concise helpers for installing/adding plugins in two stages
local add = vim.pack.add
local now_if_args, later = Config.now_if_args, Config.later

-- Tree-sitter ================================================================

-- Tree-sitter is a tool for fast incremental parsing. It converts text into
-- a hierarchical structure (called tree) that can be used to implement advanced
-- and/or more precise actions: syntax highlighting, textobjects, indent, etc.
--
-- Tree-sitter support is built into Neovim (see `:h treesitter`). However, it
-- requires two extra pieces that don't come with Neovim directly:
-- - Language parsers: programs that convert text into trees. Some are built-in
--   (like for Lua), 'nvim-treesitter' provides many others.
--   NOTE: It requires third party software to build and install parsers.
--   See the link for more info in "Requirements" section of the MiniMax README.
-- - Query files: definitions of how to extract information from trees in
--   a useful manner (see `:h treesitter-query`). 'nvim-treesitter' also provides
--   these, while 'nvim-treesitter-textobjects' provides the ones for Neovim
--   textobjects (see `:h text-objects`, `:h MiniAi.gen_spec.treesitter()`).
--
-- Add these plugins now if file (and not 'mini.starter') is shown after startup.
--
-- Troubleshooting:
-- - Run `:checkhealth vim.treesitter nvim-treesitter` to see potential issues.
-- - In case of errors related to queries for Neovim bundled parsers (like `lua`,
--   `vimdoc`, `markdown`, etc.), manually install them via 'nvim-treesitter'
--   with `:TSInstall <language>`. Be sure to have necessary system dependencies
--   (see MiniMax README section for software requirements).
now_if_args(function()
  -- Define hook to update tree-sitter parsers after plugin is updated
  local ts_update = function() vim.cmd('TSUpdate') end
  Config.on_packchanged('nvim-treesitter', { 'update' }, ts_update, ':TSUpdate')

  add({
    'https://github.com/nvim-treesitter/nvim-treesitter',
    'https://github.com/nvim-treesitter/nvim-treesitter-textobjects',
  })

  -- Define languages which will have parsers installed and auto enabled
  -- After changing this, restart Neovim once to install necessary parsers. Wait
  -- for the installation to finish before opening a file for added language(s).
  local languages = {
    -- These are already pre-installed with Neovim. Used as an example.
    'lua',
    'vim',
    'vimdoc',
    'query',
    'markdown',
    'markdown_inline',
    'python',
    -- Add here more languages with which you want to use tree-sitter
    -- To see available languages:
    -- - Execute `:=require('nvim-treesitter').get_available()`
    -- - Visit 'SUPPORTED_LANGUAGES.md' file at
    --   https://github.com/nvim-treesitter/nvim-treesitter/blob/main
  }
  local isnt_installed = function(lang)
    return #vim.api.nvim_get_runtime_file('parser/' .. lang .. '.*', false) == 0
  end
  local to_install = vim.tbl_filter(isnt_installed, languages)
  if #to_install > 0 then require('nvim-treesitter').install(to_install) end

  -- Enable tree-sitter after opening a file for a target language
  local filetypes = {}
  for _, lang in ipairs(languages) do
    for _, ft in ipairs(vim.treesitter.language.get_filetypes(lang)) do
      table.insert(filetypes, ft)
    end
  end
  local ts_start = function(ev) vim.treesitter.start(ev.buf) end
  Config.new_autocmd('FileType', filetypes, ts_start, 'Start tree-sitter')
end)

-- Language servers ===========================================================

-- Language Server Protocol (LSP) is a set of conventions that power creation of
-- language specific tools. It requires two parts:
-- - Server - program that performs language specific computations.
-- - Client - program that asks server for computations and shows results.
--
-- Here Neovim itself is a client (see `:h vim.lsp`). Language servers need to
-- be installed separately based on your OS, CLI tools, and preferences.
-- See note about 'mason.nvim' at the bottom of the file.
--
-- Neovim's team collects commonly used configurations for most language servers
-- inside 'neovim/nvim-lspconfig' plugin.
--
-- Add it now if file (and not 'mini.starter') is shown after startup.
--
-- Troubleshooting:
-- - Run `:checkhealth vim.lsp` to see potential issues.
now_if_args(function()
  add({ 'https://github.com/neovim/nvim-lspconfig' })

  -- Use `:h vim.lsp.enable()` to automatically enable language server based on
  -- the rules provided by 'nvim-lspconfig'.
  -- Use `:h vim.lsp.config()` or 'after/lsp/' directory to configure servers.
  -- Uncomment and tweak the following `vim.lsp.enable()` call to enable servers.
  vim.lsp.enable({
    'lua_ls',
    'basedpyright',
    'ruff',
    'markdown_oxide',
  })
end)

-- Formatting =================================================================

-- Programs dedicated to text formatting (a.k.a. formatters) are very useful.
-- Neovim has built-in tools for text formatting (see `:h gq` and `:h 'formatprg'`).
-- They can be used to configure external programs, but it might become tedious.
--
-- The 'stevearc/conform.nvim' plugin is a good and maintained solution for easier
-- formatting setup.
later(function()
  add({ 'https://github.com/stevearc/conform.nvim' })

  -- See also:
  -- - `:h Conform`
  -- - `:h conform-options`
  -- - `:h conform-formatters`
  require('conform').setup({
    default_format_opts = {
      -- Allow formatting from LSP server if no dedicated formatter is available
      lsp_format = 'fallback',
    },
    -- Map of filetype to formatters
    -- Make sure that necessary CLI tool is available
    formatters_by_ft = {
      lua = { 'stylua' },
      python = { 'ruff_format' },
    },
  })
end)

-- Snippets ===================================================================

-- Although 'mini.snippets' provides functionality to manage snippet files, it
-- deliberately doesn't come with those.
--
-- The 'rafamadriz/friendly-snippets' is currently the largest collection of
-- snippet files. They are organized in 'snippets/' directory (mostly) per language.
-- 'mini.snippets' is designed to work with it as seamlessly as possible.
-- See `:h MiniSnippets.gen_loader.from_lang()`.
later(function() add({ 'https://github.com/rafamadriz/friendly-snippets' }) end)

-- Honorable mentions =========================================================

-- 'mason-org/mason.nvim' (a.k.a. "Mason") is a great tool (package manager) for
-- installing external language servers, formatters, and linters. It provides
-- a unified interface for installing, updating, and deleting such programs.
--
-- The caveat is that these programs will be set up to be mostly used inside Neovim.
-- If you need them to work elsewhere, consider using other package managers.
--
-- You can use it like so:
-- now_if_args(function()
--   add({ 'https://github.com/mason-org/mason.nvim' })
--   require('mason').setup()
-- end)

-- Beautiful, usable, well maintained color schemes outside of 'mini.nvim' and
-- have full support of its highlight groups. Use if you don't like 'miniwinter'
-- enabled in 'plugin/30_mini.lua' or other suggested 'mini.hues' based ones.
-- Config.now(function()
--  -- Install only those that you need
--  add({
--    'https://github.com/sainnhe/everforest',
--    'https://github.com/Shatur/neovim-ayu',
--    'https://github.com/ellisonleao/gruvbox.nvim',
--  })
--
--   -- Enable only one
--   vim.cmd('color everforest')
-- end)

-- My plugins =================================================================

-- Mason
now_if_args(function()
  add({ 'https://github.com/mason-org/mason.nvim' })
  require('mason').setup()
end)

-- Catpuccin colorscheme
Config.now(function()
  add({
    {
      src = 'https://github.com/catppuccin/nvim',
      name = 'catppuccin',
    },
  })

  require('catppuccin').setup({
    flavour = 'mocha',
    transparent_background = true,

    -- Keep floating windows readable over a transparent terminal.
    float = {
      transparent = false,
      solid = false,
    },

    -- Usefull for :terminal buffers.
    term_colors = true,

    -- Keep integrations explicit.
    default_integrations = false,
    integrations = {
      mini = {
        enabled = true,
        indentscope_color = 'lavender',
      },
    },

    -- Customized highlights
    custom_highlights = function(colors)
      return {
        LineNr = {
          fg = colors.subtext1,
        },
        CursorLineNr = {
          fg = colors.lavender,
          style = { 'bold' },
        },
        EndOfBuffer = {
          fg = colors.subtext1,
        },
      }
    end,
  })

  vim.cmd.colorscheme('catppuccin-mocha')
end)

-- Nvim-tmux-navigation
Config.later(function()
  local is_windows = vim.fn.has('win32') == 1

  if is_windows then
    return
  end

  add({
    {
      src = 'https://github.com/alexghergh/nvim-tmux-navigation',
    },
  })

  -- MiniBasics remains responsible for navigation outside tmux.
  if not vim.env.TMUX then
    return
  end

  local navigation = require('nvim-tmux-navigation')

  navigation.setup({
    disable_when_zoomed = true,
  })

  local map = vim.keymap.set
  local opts = { silent = true }

  map('n', '<C-h>', navigation.NvimTmuxNavigateLeft, opts)
  map('n', '<C-j>', navigation.NvimTmuxNavigateDown, opts)
  map('n', '<C-k>', navigation.NvimTmuxNavigateUp, opts)
  map('n', '<C-l>', navigation.NvimTmuxNavigateRight, opts)
end)

-- LazyGit
Config.later(function()
  if vim.fn.executable('lazygit') ~= 1 then
    return
  end

  vim.api.nvim_create_user_command('LazyGit', function()
    local width = math.floor(vim.o.columns * 0.9)
    local height = math.floor(vim.o.lines * 0.9)

    local buf = vim.api.nvim_create_buf(false, true)

    local normal_float = vim.api.nvim_get_hl(0, {
      name = 'NormalFloat',
      link = false,
    })

    if normal_float.bg then
      vim.b[buf].terminal_color_0 =
        string.format('#%06x', normal_float.bg)
    end

    local win = vim.api.nvim_open_win(buf, true, {
      relative = 'editor',
      style = 'minimal',
      border = 'single',
      title = ' LazyGit ',
      title_pos = 'center',
      width = width,
      height = height,
      col = math.floor((vim.o.columns - width) / 2),
      row = math.floor((vim.o.lines - height) / 2),
    })

    vim.wo[win].winhighlight = 'Normal:NormalFloat'

    vim.wo[win].winblend = 8

    local function cleanup()
      if vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_close(win, true)
      end

      if vim.api.nvim_buf_is_valid(buf) then
        vim.api.nvim_buf_delete(buf, { force = true })
      end
    end

    local job = vim.fn.jobstart({ 'lazygit' }, {
      term = true,
      cwd = vim.fn.getcwd(),

      on_exit = function()
        vim.schedule(cleanup)
      end,
    })

    if job <= 0 then
      cleanup()
      vim.notify(
        'Could not start LazyGit',
        vim.log.level.ERROR
      )
      return
    end

    vim.cmd.startinsert()
  end, {
    desc = 'Open LazyGit in a floating terminal',
  })
end)
