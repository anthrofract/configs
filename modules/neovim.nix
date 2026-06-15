{ self, inputs, ... }:
{
  flake.commonModules.neovim =
    { ... }:
    {
      imports = [
        self.commonModules.neovim-keys
        self.commonModules.neovim-plugins
        self.commonModules.neovim-langs
        self.commonModules.neovim-lualine
      ];

      home-manager.sharedModules = [
        inputs.nixvim.homeModules.nixvim
        (
          { ... }:
          {
            programs.nixvim = {
              enable = true;
              nixpkgs.source = inputs.nixpkgs;

              globals.mapleader = " ";

              extraConfigLuaPre = ''
                vim.g.loaded_netrw = 1
                vim.g.loaded_netrwPlugin = 1
              '';

              opts = {
                cursorline = true;
                expandtab = true;
                foldlevel = 99;
                foldlevelstart = 99;
                ignorecase = true;
                inccommand = "split";
                list = true;
                listchars = {
                  nbsp = "␣";
                  tab = "» ";
                  trail = "·";
                };
                number = true;
                scrolloff = 10;
                shortmess.__raw = "vim.opt.shortmess + 'I'";
                showmode = false;
                sidescrolloff = 10;
                signcolumn = "yes";
                smartcase = true;
                swapfile = false;
                tabstop = 4;
                timeoutlen = 300;
                updatetime = 1000;
                winborder = "single";
              };

              colorschemes.bamboo = {
                enable = true;
                settings = {
                  colors.bg0 = "#1d1e1b";
                  highlights = {
                    "@comment".fg = "#838781";
                    Comment.fg = "#838781";
                    CursorLine.bg = "#272924";
                    DiffAdd.bg = "#202d07";
                    DiffDelete.bg = "#621e22";
                    StatusLine.bg = "#2b2d28";
                    StatusLineNC.bg = "#2b2d28";
                    Visual.bg = "#363931";
                    RenderMarkdownCodeInline.bg = "#1d1e1b";
                  };
                };
              };

              userCommands.Diff = {
                command = "CodeDiff";
                desc = "View diff";
              };

              autoCmd = [
                {
                  event = "TextYankPost";
                  callback.__raw = ''
                    function()
                      vim.highlight.on_yank({ timeout = 100 })
                    end
                  '';
                  desc = "Briefly highlight yanked text";
                }
                {
                  event = [
                    "BufWinEnter"
                    "WinEnter"
                  ];
                  callback.__raw = ''
                    function()
                      local current_win = vim.api.nvim_get_current_win()
                      local current_buf = vim.api.nvim_win_get_buf(current_win)
                      local current_is_aerial = vim.bo[current_buf].filetype == "aerial"

                      for _, win in ipairs(vim.api.nvim_list_wins()) do
                        if vim.w[win].codediff_restore then
                          vim.wo[win].cursorline = false
                        else
                          vim.wo[win].cursorline = current_is_aerial or win == current_win
                        end
                      end
                    end
                  '';
                  desc = "Update cursorline visibility";
                }
                {
                  event = "FocusGained";
                  command = "if getcmdwintype() == '' | checktime | endif";
                  desc = "Reload files changed on disk when Neovim gains focus";
                }
                {
                  event = "BufEnter";
                  command = "if &buftype == '' && !&modified && expand('%') != '' | exec 'checktime ' . expand('<abuf>') | endif";
                  desc = "Reload unmodified buffers changed on disk";
                }
                {
                  event = "VimEnter";
                  callback.__raw = ''
                    function()
                      if _G.checktime_timer then
                        return
                      end

                      _G.checktime_timer = vim.uv.new_timer()

                      _G.checktime_timer:start(3000, 3000, function()
                        vim.schedule(function()
                          if vim.fn.getcmdwintype() == "" then
                            vim.cmd("silent! checktime")
                          end
                        end)
                      end)
                    end
                  '';
                  desc = "Check loaded file buffers for external changes every 3 seconds";
                }
                {
                  event = "VimLeavePre";
                  callback.__raw = ''
                    function()
                      if _G.checktime_timer then
                        _G.checktime_timer:stop()
                        _G.checktime_timer:close()
                        _G.checktime_timer = nil
                      end
                    end
                  '';
                  desc = "Stop checktime timer";
                }
                {
                  event = "FileChangedShellPost";
                  callback.__raw = ''
                    function(args)
                      local bufnr = args.buf

                      vim.schedule(function()
                        if not vim.api.nvim_buf_is_valid(bufnr) or not vim.api.nvim_buf_is_loaded(bufnr) then
                          return
                        end

                        if vim.bo[bufnr].buftype ~= "" or vim.bo[bufnr].modified then
                          return
                        end

                        pcall(require("vim.lsp._changetracking")._send_did_save, bufnr)
                      end)
                    end
                  '';
                  desc = "Notify LSP clients after external file reload";
                }
                {
                  event = "LspAttach";
                  callback.__raw = ''
                    function(args)
                      local name = vim.api.nvim_buf_get_name(args.buf)
                      if name:match("^codediff://") then
                        vim.lsp.buf_detach_client(args.buf, args.data.client_id)
                      end
                    end
                  '';
                  desc = "Detach LSPs from CodeDiff virtual buffers";
                }
              ];
            };
          }
        )
      ];
    };

  flake.commonModules.neovim-plugins =
    { ... }:
    {
      home-manager.sharedModules = [
        (
          { pkgs, ... }:
          {
            programs.nixvim = {
              plugins = {
                aerial = {
                  enable = true;
                  lazyLoad = {
                    enable = true;
                    settings.event = [ "DeferredUIEnter" ];
                  };
                  settings = {
                    autojump = true;
                    close_on_select = true;
                    filter_kind = false;
                    highlight_on_jump = false;
                    nav.autojump = true;
                  };
                };
                codediff = {
                  enable = true;
                  lazyLoad = {
                    enable = true;
                    settings.event = [ "DeferredUIEnter" ];
                  };
                };
                fidget = {
                  enable = true;
                  lazyLoad = {
                    enable = true;
                    settings.event = [ "DeferredUIEnter" ];
                  };
                  settings.progress.display.render_limit = 5;
                };
                fugitive = {
                  enable = true;
                  lazyLoad = {
                    enable = true;
                    settings.event = [ "DeferredUIEnter" ];
                  };
                };
                gitsigns = {
                  enable = true;
                  lazyLoad = {
                    enable = true;
                    settings.event = [ "DeferredUIEnter" ];
                  };
                };
                hop = {
                  enable = true;
                  lazyLoad = {
                    enable = true;
                    settings.event = [ "DeferredUIEnter" ];
                  };
                };
                lz-n.enable = true;
                mini-bufremove.enable = true;
                nvim-autopairs = {
                  enable = true;
                  lazyLoad = {
                    enable = true;
                    settings.event = [ "DeferredUIEnter" ];
                  };
                  settings.check_ts = true;
                };
                nvim-bqf = {
                  enable = true;
                  lazyLoad = {
                    enable = true;
                    settings.event = [ "DeferredUIEnter" ];
                  };
                  settings.preview = {
                    border = "single";
                    winblend = 0;
                  };
                };
                nvim-surround = {
                  enable = true;
                  lazyLoad = {
                    enable = true;
                    settings.event = [ "DeferredUIEnter" ];
                  };
                };
                octo = {
                  enable = true;
                  lazyLoad = {
                    enable = true;
                    settings.cmd = [ "Octo" ];
                  };
                  settings = {
                    enable_builtin = true;
                  };
                };
                oil = {
                  enable = true;
                  lazyLoad = {
                    enable = true;
                    settings.event = [ "DeferredUIEnter" ];
                  };
                  settings = {
                    default_file_explorer = true;
                    keymaps.q = "actions.close";
                    skip_confirm_for_simple_edits = true;
                    view_options.show_hidden = true;
                  };
                };
                quicker = {
                  enable = true;
                  lazyLoad = {
                    enable = true;
                    settings.event = [ "DeferredUIEnter" ];
                  };
                };
                render-markdown = {
                  enable = true;
                  settings = {
                    file_types = [ "markdown" ];
                    sign.enabled = false;
                    code = {
                      border = "thin";
                      width = "block";
                      left_pad = 1;
                      right_pad = 1;
                      highlight = "RenderMarkdownH6Bg";
                      highlight_border = "RenderMarkdownH6Bg";
                    };
                    heading.enabled = false;
                  };
                };
                rhubarb = {
                  enable = true;
                  lazyLoad = {
                    enable = true;
                    settings.event = [ "DeferredUIEnter" ];
                  };
                };
                sleuth.enable = true;
                telescope = {
                  enable = true;
                  lazyLoad = {
                    enable = true;
                    settings.event = [ "DeferredUIEnter" ];
                  };
                  extensions.fzf-native.enable = true;
                  extensions.ui-select = {
                    enable = true;
                    settings.__raw = ''
                      require("telescope.themes").get_dropdown({
                        borderchars = {
                          prompt = { "─", "│", " ", "│", "┌", "┐", "│", "│" },
                          results = { "─", "│", "─", "│", "├", "┤", "┘", "└" },
                          preview = { "─", "│", "─", "│", "┌", "┐", "┘", "└" },
                        },
                      })
                    '';
                  };
                  settings.defaults = {
                    borderchars = [
                      "─"
                      "│"
                      "─"
                      "│"
                      "┌"
                      "┐"
                      "┘"
                      "└"
                    ];
                    layout_config.prompt_position = "top";
                    mappings.i."<Esc>".__raw = ''
                      require("telescope.actions").close
                    '';
                    sorting_strategy = "ascending";
                  };
                };
                tmux-navigator = {
                  enable = true;
                  lazyLoad = {
                    enable = true;
                    settings.event = [ "DeferredUIEnter" ];
                  };
                };
                treesitter-textobjects = {
                  enable = true;
                  lazyLoad = {
                    enable = true;
                    settings.event = [ "DeferredUIEnter" ];
                  };
                  settings.select = {
                    enable = true;
                    lookahead = true;
                  };
                };
                web-devicons = {
                  enable = true;
                  lazyLoad = {
                    enable = true;
                    settings.event = [ "DeferredUIEnter" ];
                  };
                };
              };

              extraPlugins = [
                pkgs.vimPlugins.nvim-various-textobjs
              ];
            };
          }
        )
      ];
    };

  flake.commonModules.neovim-langs =
    { ... }:
    {
      home-manager.sharedModules = [
        (
          { ... }:
          {
            programs.nixvim = {
              plugins = {
                lsp = {
                  enable = true;
                  servers = {
                    bashls.enable = true;
                    buf_ls.enable = true;
                    cssls.enable = true;
                    eslint.enable = true;
                    golangci_lint_ls.enable = true;
                    gopls.enable = true;
                    hls = {
                      enable = true;
                      installGhc = false;
                      package = null;
                    };
                    html.enable = true;
                    jsonls.enable = true;
                    lua_ls.enable = true;
                    marksman.enable = true;
                    nixd.enable = true;
                    nushell = {
                      enable = true;
                      package = null;
                    };
                    rust_analyzer = {
                      enable = true;
                      installCargo = false;
                      installRustc = false;
                      package = null;
                      settings = {
                        cargo.features = "all";
                        check = {
                          command = "clippy";
                          features = "all";
                        };
                        # rust-analyzer can emit false-positive unresolvedReference semantic tokens
                        semanticHighlighting.nonStandardTokens = false;
                      };
                    };
                    tombi.enable = true;
                    ts_ls.enable = true;
                    ty.enable = true;
                  };
                };

                blink-cmp = {
                  enable = true;
                  settings = {
                    completion = {
                      documentation.auto_show = true;
                      menu.draw.components.kind_icon.text.__raw = ''
                        function(ctx)
                          if ctx.source_id == "cmdline" then
                            return ""
                          end

                          return ctx.kind_icon .. ctx.icon_gap
                        end
                      '';
                    };
                    signature.enabled = true;
                    keymap = {
                      "<C-space>" = [
                        "select_and_accept"
                        "fallback"
                      ];
                      preset = "default";
                    };
                  };
                };

                conform-nvim = {
                  enable = true;
                  settings = {
                    format_on_save = {
                      lsp_format = "never";
                      timeout_ms = 500;
                    };
                    formatters_by_ft = {
                      bash = [ "shfmt" ];
                      go = [ "gofmt" ];
                      haskell = [ "ormolu" ];
                      javascript = [ "prettier" ];
                      json = [ "prettier" ];
                      jsonc = [ "prettier" ];
                      lua = [ "stylua" ];
                      nix = [ "nixfmt" ];
                      proto = [ "buf" ];
                      python = [ "black" ];
                      rust = [ "rustfmt" ];
                      sh = [ "shfmt" ];
                      toml = [ "tombi" ];
                      typescript = [ "prettier" ];
                    };
                    notify_no_formatters = false;
                    notify_on_error = false;
                  };
                };

                treesitter = {
                  enable = true;
                  folding.enable = true;
                  highlight.enable = true;
                  indent.enable = false;
                };
              };

              diagnostic.settings.signs.text = {
                "__rawKey__vim.diagnostic.severity.ERROR" = "●";
                "__rawKey__vim.diagnostic.severity.HINT" = "●";
                "__rawKey__vim.diagnostic.severity.INFO" = "●";
                "__rawKey__vim.diagnostic.severity.WARN" = "●";
              };
              diagnostic.settings.virtual_lines.current_line = true;
            };
          }
        )
      ];
    };

  flake.commonModules.neovim-lualine =
    { ... }:
    {
      home-manager.sharedModules = [
        (
          { ... }:
          {
            programs.nixvim.plugins = {
              lualine = {
                enable = true;
                settings = {
                  inactive_sections = {
                    lualine_a = [ ];
                    lualine_b = [ ];
                    lualine_c = [
                      {
                        __unkeyed-1 = "filename";
                        file_status = true;
                        path = 3;
                        symbols.unnamed = "∅";
                      }
                    ];
                    lualine_x = [ ];
                    lualine_y = [ ];
                    lualine_z = [ ];
                  };
                  options = {
                    component_separators = {
                      left = "";
                      right = "";
                    };
                    section_separators = {
                      left = "";
                      right = "";
                    };
                  };
                  sections = {
                    lualine_a = [ "mode" ];
                    lualine_b = [
                      {
                        __unkeyed-1 = "filetype";
                        icon_only = true;
                      }
                      {
                        __unkeyed-1 = "diagnostics";
                        sources = [ "nvim_lsp" ];
                      }
                    ];
                    lualine_c = [
                      {
                        __unkeyed-1 = "filename";
                        file_status = true;
                        path = 1;
                        symbols.unnamed = "∅";
                      }
                      {
                        __unkeyed-1 = "lsp_status";
                        icon = "";
                        padding = {
                          left = 0;
                          right = 0;
                        };
                        fmt.__raw = ''
                          function(status)
                            if status == "" then
                              return ""
                            end

                            for _, spinner in ipairs({ "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }) do
                              if status:find(spinner, 1, true) then
                                return spinner
                              end
                            end

                            return ""
                          end
                        '';
                      }
                    ];
                    lualine_x = [
                      {
                        __unkeyed-1.__raw = ''
                          function()
                            return vim.fn.fnamemodify(vim.fn.getcwd(), ":~")
                          end
                        '';
                      }
                      "diff"
                      {
                        __unkeyed-1 = "branch";
                        icon = "";
                        padding = {
                          left = 0;
                          right = 1;
                        };
                      }
                    ];
                    lualine_y = [
                      "progress"
                      {
                        __unkeyed-1.__raw = ''
                          function()
                            local lines = vim.api.nvim_buf_line_count(0)
                            local current_line = vim.api.nvim_get_current_line()
                            local cols = vim.fn.strdisplaywidth(current_line)
                            return string.format("%d:%d", lines, cols)
                          end
                        '';
                      }
                    ];
                    lualine_z = [ "location" ];
                  };
                };
              };
            };
          }
        )
      ];
    };

  flake.commonModules.neovim-keys =
    { ... }:
    {
      home-manager.sharedModules = [
        (
          { ... }:
          {
            programs.nixvim = {
              extraConfigLua = ''
                vim.keymap.del("n", "grn")
                vim.keymap.del({ "n", "x" }, "gra")
                vim.keymap.del("n", "grx")
                vim.keymap.del("n", "grr")
                vim.keymap.del("n", "gri")
                vim.keymap.del("n", "grt")
              '';

              keymaps = [
                {
                  mode = "n";
                  key = "-";
                  action.__raw = ''
                    function()
                      require("oil").open(nil, { preview = {} })
                    end
                  '';
                  options.desc = "Open file explorer at current buffer's directory";
                }
                {
                  mode = "n";
                  key = "<";
                  action = "<<";
                  options.desc = "Outdent line";
                }
                {
                  mode = "n";
                  key = "<A-S>";
                  action = "<cmd>w<CR>";
                  options.desc = "Save file";
                }
                {
                  mode = "n";
                  key = "<Esc>";
                  action.__raw = ''
                    function()
                      vim.cmd("nohlsearch")
                      pcall(vim.lsp.buf.clear_references)

                      for _, win in ipairs(vim.api.nvim_list_wins()) do
                        local config = vim.api.nvim_win_get_config(win)
                        if config.relative ~= "" then
                          pcall(vim.api.nvim_win_close, win, true)
                        end
                      end

                      vim.cmd("echo")
                    end
                  '';
                  options.desc = "Clear highlights, messages, and popups";
                }
                {
                  mode = "n";
                  key = "<CR>";
                  action = "G";
                  options.desc = "Go to line";
                }
                {
                  mode = "n";
                  key = "<leader>'";
                  action = "<cmd>Telescope resume<CR>";
                  options.desc = "Open last picker";
                }
                {
                  mode = "n";
                  key = "<leader>/";
                  action = "<cmd>Telescope live_grep<CR>";
                  options.desc = "Global search in workspace folder";
                }
                {
                  mode = "n";
                  key = "<leader>A";
                  action.__raw = ''
                    function()
                      vim.lsp.buf.code_action()
                    end
                  '';
                  options.desc = "Perform code action";
                }
                {
                  mode = "n";
                  key = "<leader>bb";
                  action = "<cmd>Telescope buffers<CR>";
                  options.desc = "Open buffer picker";
                }
                {
                  mode = "n";
                  key = "<leader>bl";
                  action = "<C-^>";
                  options.desc = "Go to last accessed file";
                }
                {
                  mode = "n";
                  key = "<leader>bn";
                  action = "<cmd>bnext<CR>";
                  options.desc = "Go to next buffer";
                }
                {
                  mode = "n";
                  key = "<leader>bp";
                  action = "<cmd>bprevious<CR>";
                  options.desc = "Go to previous buffer";
                }
                {
                  mode = "n";
                  key = "<leader>bq";
                  action.__raw = ''
                    function()
                      require("mini.bufremove").delete(0, false)
                    end
                  '';
                  options.desc = "Close buffer";
                }
                {
                  mode = "n";
                  key = "<leader>br";
                  action = "<cmd>edit!<CR>";
                  options.desc = "Reload buffer from disk";
                }
                {
                  mode = "n";
                  key = "<leader>bx";
                  action = "<cmd>enew<CR>";
                  options.desc = "New scratch buffer";
                }
                {
                  mode = "n";
                  key = "<leader>c";
                  action = "gcc";
                  options.desc = "Comment/uncomment selections";
                  options.remap = true;
                }
                {
                  mode = "x";
                  key = "<leader>c";
                  action = "gc";
                  options.desc = "Comment/uncomment selections";
                  options.remap = true;
                }
                {
                  mode = "n";
                  key = "<leader>D";
                  action.__raw = ''
                    function()
                      require("telescope.builtin").diagnostics()
                    end
                  '';
                  options.desc = "Open workspace diagnostic picker";
                }
                {
                  mode = "n";
                  key = "<leader>d";
                  action.__raw = ''
                    function()
                      require("telescope.builtin").diagnostics({ bufnr = 0 })
                    end
                  '';
                  options.desc = "Open diagnostic picker";
                }
                {
                  mode = "n";
                  key = "<leader>e";
                  action.__raw = ''
                    function()
                      require("oil").open(".", { preview = {} })
                    end
                  '';
                  options.desc = "Open file explorer in workspace root";
                }
                {
                  mode = "n";
                  key = "<leader>E";
                  action.__raw = ''
                    function()
                      require("oil").open(nil, { preview = {} })
                    end
                  '';
                  options.desc = "Open file explorer at current buffer's directory";
                }
                {
                  mode = "n";
                  key = "<leader>f";
                  action = "<cmd>Telescope find_files<CR>";
                  options.desc = "Open file picker";
                }
                {
                  mode = "n";
                  key = "<leader>gg";
                  action = "<cmd>Telescope git_status<CR>";
                  options.desc = "Open changed file picker";
                }
                {
                  mode = "n";
                  key = "<leader>gb";
                  action.__raw = ''
                    function()
                      for _, win in ipairs(vim.api.nvim_list_wins()) do
                        local buf = vim.api.nvim_win_get_buf(win)

                        if vim.bo[buf].filetype == "gitsigns-blame" then
                          vim.api.nvim_win_close(win, true)
                          return
                        end
                      end

                      require("gitsigns").blame()
                    end
                  '';
                  options.desc = "Toggle git blame";
                }
                {
                  mode = "n";
                  key = "<leader>gC";
                  action.__raw = ''
                    function()
                      require("gitsigns").setqflist("all")
                    end
                  '';
                  options.desc = "Open workspace changes in quickfix";
                }
                {
                  mode = "n";
                  key = "<leader>gc";
                  action.__raw = ''
                    function()
                      require("gitsigns").setqflist()
                    end
                  '';
                  options.desc = "Open buffer changes in quickfix";
                }
                {
                  mode = "n";
                  key = "<leader>gd";
                  action = "<cmd>CodeDiff<CR>";
                  options.desc = "View diff";
                }
                {
                  mode = "n";
                  key = "<leader>gh";
                  action = "<cmd>GBrowse<CR>";
                  options.desc = "Open in GitHub";
                }
                {
                  mode = "x";
                  key = "<leader>gh";
                  action = ":'<,'>GBrowse<CR>";
                  options.desc = "Open in GitHub";
                }
                {
                  mode = "n";
                  key = "<leader>h";
                  action.__raw = ''
                    function()
                      vim.lsp.buf.document_highlight()
                    end
                  '';
                  options.desc = "Highlight symbol references";
                }
                {
                  mode = "n";
                  key = "<leader>j";
                  action = "<cmd>Telescope jumplist<CR>";
                  options.desc = "Open jumplist picker";
                }
                {
                  mode = "n";
                  key = "<leader>k";
                  action.__raw = ''
                    function()
                      vim.lsp.buf.hover()
                    end
                  '';
                  options.desc = "Show docs for item under cursor";
                }
                {
                  mode = "n";
                  key = "<leader>l";
                  action.__raw = ''
                    function()
                      local path = vim.api.nvim_buf_get_name(0)
                      local line = vim.fn.line(".")
                      vim.fn.setreg("+", string.format("@%s L%s-L%s", path, line, line))
                    end
                  '';
                  options.desc = "Copy file path and line number";
                }
                {
                  mode = "x";
                  key = "<leader>l";
                  action.__raw = ''
                    function()
                      local path = vim.api.nvim_buf_get_name(0)
                      local start_line = vim.fn.line("v")
                      local end_line = vim.fn.line(".")

                      if start_line > end_line then
                        start_line, end_line = end_line, start_line
                      end

                      vim.fn.setreg("+", string.format("@%s L%s-L%s", path, start_line, end_line))
                    end
                  '';
                  options.desc = "Copy file path and line numbers";
                }
                {
                  mode = "n";
                  key = "<leader>m";
                  action.__raw = ''
                    function()
                      require("telescope.builtin").oldfiles({ cwd_only = true })
                    end
                  '';
                  options.desc = "Open recent files picker";
                }
                {
                  mode = "n";
                  key = "<leader>o";
                  action = "<cmd>AerialToggle<CR>";
                  options.desc = "Open outline";
                }
                {
                  mode = [
                    "n"
                    "x"
                  ];
                  key = "<leader>P";
                  action = "\"+P";
                  options.desc = "Paste clipboard before selection";
                }
                {
                  mode = [
                    "n"
                    "x"
                  ];
                  key = "<leader>p";
                  action = "\"+p";
                  options.desc = "Paste clipboard after selection";
                }
                {
                  mode = "n";
                  key = "<leader>q";
                  action = "<cmd>qa<CR>";
                  options.desc = "Quit all windows";
                }
                {
                  mode = "n";
                  key = "<leader>Q";
                  action = "<cmd>qa!<CR>";
                  options.desc = "Force quit all windows";
                }
                {
                  mode = "n";
                  key = "<leader>r";
                  action.__raw = ''
                    function()
                      vim.lsp.buf.rename()
                    end
                  '';
                  options.desc = "Rename symbol";
                }
                {
                  mode = "n";
                  key = "<leader>s";
                  action = "<cmd>Telescope lsp_document_symbols<CR>";
                  options.desc = "Open symbol picker";
                }
                {
                  mode = "n";
                  key = "<leader>S";
                  action = "<cmd>Telescope lsp_dynamic_workspace_symbols<CR>";
                  options.desc = "Open workspace symbol picker";
                }
                {
                  mode = "n";
                  key = "<leader>v";
                  action = "ggVG";
                  options.desc = "Select all";
                }
                {
                  mode = "n";
                  key = "<leader>w<Down>";
                  action = "<C-w>j";
                  options.desc = "Jump to split below";
                }
                {
                  mode = "n";
                  key = "<leader>w<Left>";
                  action = "<C-w>h";
                  options.desc = "Jump to left split";
                }
                {
                  mode = "n";
                  key = "<leader>w<Right>";
                  action = "<C-w>l";
                  options.desc = "Jump to right split";
                }
                {
                  mode = "n";
                  key = "<leader>w<Up>";
                  action = "<C-w>k";
                  options.desc = "Jump to split above";
                }
                {
                  mode = "n";
                  key = "<leader>wh";
                  action = "<C-w>h";
                  options.desc = "Jump to left split";
                }
                {
                  mode = "n";
                  key = "<leader>wH";
                  action.__raw = ''
                    function()
                      local current = vim.api.nvim_get_current_win()
                      vim.cmd("wincmd h")
                      local target = vim.api.nvim_get_current_win()

                      if target == current then
                        return
                      end

                      vim.api.nvim_set_current_win(current)
                      vim.cmd(vim.fn.win_id2win(target) .. "wincmd x")
                    end
                  '';
                  options.desc = "Swap with left split";
                }
                {
                  mode = "n";
                  key = "<leader>wj";
                  action = "<C-w>j";
                  options.desc = "Jump to split below";
                }
                {
                  mode = "n";
                  key = "<leader>wJ";
                  action.__raw = ''
                    function()
                      local current = vim.api.nvim_get_current_win()
                      vim.cmd("wincmd j")
                      local target = vim.api.nvim_get_current_win()

                      if target == current then
                        return
                      end

                      vim.api.nvim_set_current_win(current)
                      vim.cmd(vim.fn.win_id2win(target) .. "wincmd x")
                    end
                  '';
                  options.desc = "Swap with split below";
                }
                {
                  mode = "n";
                  key = "<leader>wk";
                  action = "<C-w>k";
                  options.desc = "Jump to split above";
                }
                {
                  mode = "n";
                  key = "<leader>wK";
                  action.__raw = ''
                    function()
                      local current = vim.api.nvim_get_current_win()
                      vim.cmd("wincmd k")
                      local target = vim.api.nvim_get_current_win()

                      if target == current then
                        return
                      end

                      vim.api.nvim_set_current_win(current)
                      vim.cmd(vim.fn.win_id2win(target) .. "wincmd x")
                    end
                  '';
                  options.desc = "Swap with split above";
                }
                {
                  mode = "n";
                  key = "<leader>wl";
                  action = "<C-w>l";
                  options.desc = "Jump to right split";
                }
                {
                  mode = "n";
                  key = "<leader>wL";
                  action.__raw = ''
                    function()
                      local current = vim.api.nvim_get_current_win()
                      vim.cmd("wincmd l")
                      local target = vim.api.nvim_get_current_win()

                      if target == current then
                        return
                      end

                      vim.api.nvim_set_current_win(current)
                      vim.cmd(vim.fn.win_id2win(target) .. "wincmd x")
                    end
                  '';
                  options.desc = "Swap with right split";
                }
                {
                  mode = "n";
                  key = "<leader>wns";
                  action = "<cmd>botright split | enew<CR>";
                  options.desc = "Horizontal bottom split scratch buffer";
                }
                {
                  mode = "n";
                  key = "<leader>wnv";
                  action = "<cmd>botright vsplit | enew<CR>";
                  options.desc = "Vertical right split scratch buffer";
                }
                {
                  mode = "n";
                  key = "<leader>wo";
                  action = "<C-w>o";
                  options.desc = "Close windows except current";
                }
                {
                  mode = "n";
                  key = "<leader>wq";
                  action = "<C-w>q";
                  options.desc = "Close window";
                }
                {
                  mode = "n";
                  key = "<leader>ws";
                  action = "<cmd>botright split<CR>";
                  options.desc = "Horizontal bottom split";
                }
                {
                  mode = "n";
                  key = "<leader>wt";
                  action.__raw = ''
                    function()
                      local layout = vim.fn.winlayout()[1]

                      if layout == "row" then
                        vim.cmd("wincmd K")
                      elseif layout == "col" then
                        vim.cmd("wincmd H")
                      end
                    end
                  '';
                  options.desc = "Transpose splits";
                }
                {
                  mode = "n";
                  key = "<leader>wv";
                  action = "<cmd>botright vsplit<CR>";
                  options.desc = "Vertical right split";
                }
                {
                  mode = "n";
                  key = "<leader>ww";
                  action = "<C-w>w";
                  options.desc = "Go to next window";
                }
                {
                  mode = [
                    "n"
                    "x"
                  ];
                  key = "<leader>y";
                  action = "\"+y";
                  options.desc = "Yank selection to clipboard";
                }
                {
                  mode = "n";
                  key = ">";
                  action = ">>";
                  options.desc = "Indent line";
                }
                {
                  mode = "n";
                  key = "[a";
                  action.__raw = ''
                    function()
                      require("nvim-treesitter-textobjects.move").goto_previous_start("@parameter.outer", "textobjects")
                    end
                  '';
                  options.desc = "Go to previous argument";
                }
                {
                  mode = "n";
                  key = "[c";
                  action.__raw = ''
                    function()
                      require("nvim-treesitter-textobjects.move").goto_previous_start("@comment.outer", "textobjects")
                    end
                  '';
                  options.desc = "Go to previous comment";
                }
                {
                  mode = "n";
                  key = "[e";
                  action.__raw = ''
                    function()
                      require("nvim-treesitter-textobjects.move").goto_previous_start("@block.inner", "textobjects")
                    end
                  '';
                  options.desc = "Go to previous data structure";
                }
                {
                  mode = "n";
                  key = "[f";
                  action.__raw = ''
                    function()
                      require("nvim-treesitter-textobjects.move").goto_previous_start("@function.outer", "textobjects")
                    end
                  '';
                  options.desc = "Go to previous function";
                }
                {
                  mode = "n";
                  key = "[g";
                  action.__raw = ''
                    function()
                      require("gitsigns").nav_hunk("prev")
                    end
                  '';
                  options.desc = "Go to previous change";
                }
                {
                  mode = "n";
                  key = "[p";
                  action = "{";
                  options.desc = "Go to previous paragraph";
                }
                {
                  mode = "n";
                  key = "[o";
                  action = "<cmd>AerialPrev<CR>";
                  options.desc = "Go to previous outline node";
                }
                {
                  mode = "n";
                  key = "[t";
                  action.__raw = ''
                    function()
                      require("nvim-treesitter-textobjects.move").goto_previous_start("@class.outer", "textobjects")
                    end
                  '';
                  options.desc = "Go to previous type definition";
                }
                {
                  mode = "n";
                  key = "]a";
                  action.__raw = ''
                    function()
                      require("nvim-treesitter-textobjects.move").goto_next_start("@parameter.outer", "textobjects")
                    end
                  '';
                  options.desc = "Go to next argument";
                }
                {
                  mode = "n";
                  key = "]c";
                  action.__raw = ''
                    function()
                      require("nvim-treesitter-textobjects.move").goto_next_start("@comment.outer", "textobjects")
                    end
                  '';
                  options.desc = "Go to next comment";
                }
                {
                  mode = "n";
                  key = "]e";
                  action.__raw = ''
                    function()
                      require("nvim-treesitter-textobjects.move").goto_next_start("@block.inner", "textobjects")
                    end
                  '';
                  options.desc = "Go to next data structure";
                }
                {
                  mode = "n";
                  key = "]f";
                  action.__raw = ''
                    function()
                      require("nvim-treesitter-textobjects.move").goto_next_start("@function.outer", "textobjects")
                    end
                  '';
                  options.desc = "Go to next function";
                }
                {
                  mode = "n";
                  key = "]g";
                  action.__raw = ''
                    function()
                      require("gitsigns").nav_hunk("next")
                    end
                  '';
                  options.desc = "Go to next change";
                }
                {
                  mode = "n";
                  key = "]p";
                  action = "}";
                  options.desc = "Go to next paragraph";
                }
                {
                  mode = "n";
                  key = "]o";
                  action = "<cmd>AerialNext<CR>";
                  options.desc = "Go to next outline node";
                }
                {
                  mode = "n";
                  key = "]t";
                  action.__raw = ''
                    function()
                      require("nvim-treesitter-textobjects.move").goto_next_start("@class.outer", "textobjects")
                    end
                  '';
                  options.desc = "Go to next type definition";
                }
                {
                  mode = "n";
                  key = "gd";
                  action.__raw = ''
                    function()
                      require("telescope.builtin").lsp_definitions()
                    end
                  '';
                  options.desc = "Go to definition";
                }
                {
                  mode = "n";
                  key = "gD";
                  action.__raw = ''
                    function()
                      vim.lsp.buf.declaration()
                    end
                  '';
                  options.desc = "Go to declaration";
                }
                {
                  mode = "n";
                  key = "gh";
                  action = "0";
                  options.desc = "Go to line start";
                }
                {
                  mode = "n";
                  key = "gI";
                  action.__raw = ''
                    function()
                      require("telescope.builtin").lsp_implementations()
                    end
                  '';
                  options.desc = "Go to implementation";
                }
                {
                  mode = "n";
                  key = "gl";
                  action = "$";
                  options.desc = "Go to line end";
                }
                {
                  mode = "n";
                  key = "gr";
                  action.__raw = ''
                    function()
                      require("telescope.builtin").lsp_references()
                    end
                  '';
                  options.desc = "Go to references";
                }
                {
                  mode = "n";
                  key = "gs";
                  action = "^";
                  options.desc = "Go to first non-blank in line";
                }
                {
                  mode = [
                    "n"
                    "x"
                    "o"
                  ];
                  key = "gw";
                  action = "<cmd>HopWord<CR>";
                  options.desc = "Jump to a two-character label";
                }
                {
                  mode = "n";
                  key = "gy";
                  action.__raw = ''
                    function()
                      require("telescope.builtin").lsp_type_definitions()
                    end
                  '';
                  options.desc = "Go to type definition";
                }
                {
                  mode = "n";
                  key = "U";
                  action = "<C-r>";
                  options.desc = "Redo";
                }
                {
                  mode = [
                    "x"
                    "o"
                  ];
                  key = "aa";
                  action.__raw = ''
                    function()
                      require("nvim-treesitter-textobjects.select").select_textobject("@parameter.outer", "textobjects")
                    end
                  '';
                  options.desc = "outer argument";
                }
                {
                  mode = [
                    "x"
                    "o"
                  ];
                  key = "ia";
                  action.__raw = ''
                    function()
                      require("nvim-treesitter-textobjects.select").select_textobject("@parameter.inner", "textobjects")
                    end
                  '';
                  options.desc = "inner argument";
                }
                {
                  mode = [
                    "x"
                    "o"
                  ];
                  key = "au";
                  action.__raw = ''
                    function()
                      require("various-textobjs").subword("outer")
                    end
                  '';
                  options.desc = "subword";
                }
                {
                  mode = [
                    "x"
                    "o"
                  ];
                  key = "iu";
                  action.__raw = ''
                    function()
                      require("various-textobjs").subword("inner")
                    end
                  '';
                  options.desc = "subword";
                }
                {
                  mode = [
                    "x"
                    "o"
                  ];
                  key = "ac";
                  action.__raw = ''
                    function()
                      require("nvim-treesitter-textobjects.select").select_textobject("@comment.outer", "textobjects")
                    end
                  '';
                  options.desc = "outer comment";
                }
                {
                  mode = [
                    "x"
                    "o"
                  ];
                  key = "ic";
                  action.__raw = ''
                    function()
                      require("nvim-treesitter-textobjects.select").select_textobject("@comment.inner", "textobjects")
                    end
                  '';
                  options.desc = "inner comment";
                }
                {
                  mode = [
                    "x"
                    "o"
                  ];
                  key = "ae";
                  action.__raw = ''
                    function()
                      require("nvim-treesitter-textobjects.select").select_textobject("@block.outer", "textobjects")
                    end
                  '';
                  options.desc = "outer data structure";
                }
                {
                  mode = [
                    "x"
                    "o"
                  ];
                  key = "ie";
                  action.__raw = ''
                    function()
                      require("nvim-treesitter-textobjects.select").select_textobject("@block.inner", "textobjects")
                    end
                  '';
                  options.desc = "inner data structure";
                }
                {
                  mode = [
                    "x"
                    "o"
                  ];
                  key = "af";
                  action.__raw = ''
                    function()
                      require("nvim-treesitter-textobjects.select").select_textobject("@function.outer", "textobjects")
                    end
                  '';
                  options.desc = "outer function";
                }
                {
                  mode = [
                    "x"
                    "o"
                  ];
                  key = "if";
                  action.__raw = ''
                    function()
                      require("nvim-treesitter-textobjects.select").select_textobject("@function.inner", "textobjects")
                    end
                  '';
                  options.desc = "inner function";
                }
                {
                  mode = [
                    "x"
                    "o"
                  ];
                  key = "ag";
                  action.__raw = ''
                    function()
                      require("gitsigns").select_hunk()
                    end
                  '';
                  options.desc = "changed hunk";
                }
                {
                  mode = [
                    "x"
                    "o"
                  ];
                  key = "ig";
                  action.__raw = ''
                    function()
                      require("gitsigns").select_hunk()
                    end
                  '';
                  options.desc = "changed hunk";
                }
                {
                  mode = [
                    "x"
                    "o"
                  ];
                  key = "at";
                  action.__raw = ''
                    function()
                      require("nvim-treesitter-textobjects.select").select_textobject("@class.outer", "textobjects")
                    end
                  '';
                  options.desc = "outer type definition";
                }
                {
                  mode = [
                    "x"
                    "o"
                  ];
                  key = "it";
                  action.__raw = ''
                    function()
                      require("nvim-treesitter-textobjects.select").select_textobject("@class.inner", "textobjects")
                    end
                  '';
                  options.desc = "inner type definition";
                }
              ];
              plugins.which-key = {
                enable = true;
                settings = {
                  delay = 0;
                  icons.mappings = false;
                  icons.separator = "";
                  preset = "helix";
                  show_help = false;
                  spec = [
                    {
                      __unkeyed-1 = "<leader>b";
                      group = "Buffer";
                    }
                    {
                      __unkeyed-1 = "<leader>g";
                      group = "Vcs";
                    }
                    {
                      __unkeyed-1 = "<leader>w";
                      group = "Window";
                    }
                    {
                      __unkeyed-1 = "<leader>wn";
                      group = "New split scratch buffer";
                    }
                  ];
                  replace.desc = [
                    {
                      __raw = ''
                        function(desc)
                          desc = desc:gsub("<Plug>%(?(.*)%)?", "%1")
                          desc = desc:gsub("^%+", "")
                          desc = desc:gsub("<[cC]md>", "")
                          desc = desc:gsub("<[cC][rR]>", "")
                          desc = desc:gsub("<[sS]ilent>", "")
                          desc = desc:gsub("^lua%s+", "")
                          desc = desc:gsub("^call%s+", "")
                          desc = desc:gsub("^:%s*", "")
                          return "  " .. desc
                        end
                      '';
                    }
                  ];
                  win.border = "single";
                };
              };

            };
          }
        )
      ];
    };
}
