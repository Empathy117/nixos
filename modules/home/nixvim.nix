{
  pkgs,
  ...
}:
{
  programs.nixvim = {
    enable = true;
    nixpkgs.source = pkgs.path;

    colorschemes.catppuccin = {
      enable = true;
      settings.transparent_background = true;
    };

    extraPlugins = [
      pkgs.vimPlugins.opencode-nvim
      pkgs.vimPlugins."vim-suda"
    ];

    opts = {
      clipboard = "unnamedplus";
      number = true;
      relativenumber = true;
      cursorline = true;
      signcolumn = "yes";
      termguicolors = true;
      updatetime = 300;
      timeoutlen = 400;
      splitright = true;
      splitbelow = true;
      ignorecase = true;
      smartcase = true;
      undofile = true;
    };

    extraConfigLua = ''
      vim.g.mapleader = " "
      vim.o.autoread = true
    '';

    keymaps = [
      {
        key = "<leader>ff";
        action = "<cmd>Telescope find_files<CR>";
        options.desc = "Find files";
      }
      {
        key = "<leader>fg";
        action = "<cmd>Telescope live_grep<CR>";
        options.desc = "Live grep";
      }
      {
        key = "<leader>fb";
        action = "<cmd>Telescope buffers<CR>";
        options.desc = "Find buffers";
      }
      {
        key = "<leader>fh";
        action = "<cmd>Telescope help_tags<CR>";
        options.desc = "Help tags";
      }
      {
        key = "<leader>e";
        action = "<cmd>NvimTreeToggle<CR>";
        options.desc = "File tree";
      }
      {
        key = "<leader>gg";
        action = "<cmd>LazyGit<CR>";
        options.desc = "LazyGit";
      }
      {
        key = "<leader>oa";
        action.__raw = ''
          function()
            require("opencode").ask("@this: ", { submit = true })
          end
        '';
        options.desc = "Opencode ask";
      }
      {
        key = "<leader>oo";
        action.__raw = ''
          function()
            require("opencode").select()
          end
        '';
        options.desc = "Opencode actions";
      }
      {
        key = "<leader>ot";
        action.__raw = ''
          function()
            require("opencode").toggle()
          end
        '';
        options.desc = "Opencode toggle";
      }
      {
        key = "<leader>df";
        action.__raw = ''
          function()
            require("conform").format({ lsp_format = "fallback", async = true })
          end
        '';
        options.desc = "Format buffer";
      }
      {
        key = "<leader>db";
        action.__raw = ''
          function()
            require("dap").toggle_breakpoint()
          end
        '';
        options.desc = "DAP breakpoint";
      }
      {
        key = "<leader>dc";
        action.__raw = ''
          function()
            require("dap").continue()
          end
        '';
        options.desc = "DAP continue";
      }
      {
        key = "<leader>do";
        action.__raw = ''
          function()
            require("dap").step_over()
          end
        '';
        options.desc = "DAP step over";
      }
      {
        key = "<leader>di";
        action.__raw = ''
          function()
            require("dap").step_into()
          end
        '';
        options.desc = "DAP step into";
      }
      {
        key = "<leader>dr";
        action.__raw = ''
          function()
            require("dap").repl.open()
          end
        '';
        options.desc = "DAP repl";
      }
      {
        key = "<leader>du";
        action.__raw = ''
          function()
            require("dapui").toggle()
          end
        '';
        options.desc = "DAP UI";
      }
    ];

    plugins.web-devicons.enable = true;

    plugins.which-key.enable = true;

    plugins.telescope = {
      enable = true;
      keymaps = {
        "<leader>ff" = "find_files";
        "<leader>fg" = "live_grep";
        "<leader>fb" = "buffers";
        "<leader>fh" = "help_tags";
      };
    };

    plugins.nvim-tree.enable = true;

    plugins.gitsigns.enable = true;

    plugins.lazygit.enable = true;

    plugins.treesitter = {
      enable = true;
      highlight.enable = true;
      indent.enable = true;
    };

    plugins.lualine = {
      enable = true;
      settings = {
        options = {
          theme = "catppuccin";
          globalstatus = true;
        };
        sections = {
          lualine_z = [
            {
              __unkeyed-1.__raw = ''
                require("opencode").statusline
              '';
            }
            "location"
          ];
        };
      };
    };

    plugins.cmp = {
      enable = true;
      autoEnableSources = true;
      settings = {
        snippet.expand.__raw = ''
          function(args)
            require("luasnip").lsp_expand(args.body)
          end
        '';
        mapping.__raw = ''
          require("cmp").mapping.preset.insert({
            ["<C-Space>"] = require("cmp").mapping.complete(),
            ["<CR>"] = require("cmp").mapping.confirm({ select = true }),
            ["<Tab>"] = require("cmp").mapping(function(fallback)
              local luasnip = require("luasnip")
              if require("cmp").visible() then
                require("cmp").select_next_item()
              elseif luasnip.expand_or_jumpable() then
                luasnip.expand_or_jump()
              else
                fallback()
              end
            end, { "i", "s" }),
            ["<S-Tab>"] = require("cmp").mapping(function(fallback)
              local luasnip = require("luasnip")
              if require("cmp").visible() then
                require("cmp").select_prev_item()
              elseif luasnip.jumpable(-1) then
                luasnip.jump(-1)
              else
                fallback()
              end
            end, { "i", "s" }),
          })
        '';
        sources = [
          { name = "nvim_lsp"; }
          { name = "luasnip"; }
          { name = "path"; }
          { name = "buffer"; }
        ];
      };
    };

    plugins.luasnip.enable = true;
    plugins.friendly-snippets.enable = true;

    plugins.lsp = {
      enable = true;
      inlayHints = true;
      servers = {
        pylsp.enable = true;
        nixd.enable = true;
        jdtls.enable = true;
      };
      keymaps = {
        diagnostic = {
          "<leader>dn" = "goto_next";
          "<leader>dp" = "goto_prev";
        };
        lspBuf = {
          gd = "definition";
          gD = "declaration";
          gr = "references";
          gi = "implementation";
          K = "hover";
          "<leader>rn" = "rename";
          "<leader>ca" = "code_action";
        };
      };
    };

    plugins.conform-nvim = {
      enable = true;
      autoInstall.enable = true;
      settings = {
        formatters_by_ft = {
          python = [
            "isort"
            "black"
          ];
          nix = [ "nixfmt" ];
        };
        format_on_save = {
          lsp_format = "fallback";
          timeout_ms = 1000;
        };
      };
    };

    plugins.dap.enable = true;
    plugins.dap-ui.enable = true;
    plugins.dap-python.enable = true;
  };
}
