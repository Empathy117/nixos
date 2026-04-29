{
  pkgs,
  lib,
  inputs ? { },
  ...
}:
let
  opencodeBase =
    if pkgs ? opencode then
      pkgs.opencode
    else if inputs ? opencode then
      inputs.opencode.packages.${pkgs.stdenv.hostPlatform.system}.default
    else
      throw "opencode package is not available in pkgs or inputs";
  localMcp =
    lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
      playwright = {
        type = "local";
        enabled = true;
        timeout = 30000;
        command = [
          "${pkgs.nodejs}/bin/npx"
          "-y"
          "@playwright/mcp@latest"
          "--browser"
          "chrome"
          "--executable-path"
          "/run/current-system/sw/bin/google-chrome"
          "--headless"
        ];
      };
    };
in
{
  programs.opencode = {
    enable = true;
    package = opencodeBase;
    settings = {
      autoupdate = false;
      share = "manual";
      plugin = [
        "oh-my-opencode"
      ];
      lsp = {
        nixd = {
          command = [
            "nixd"
          ];
        };
        pyright = {
          command = [
            "pyright-langserver"
            "--stdio"
          ];
        };
      };
      mcp = {
        websearch = {
          type = "remote";
          url = "https://mcp.exa.ai/mcp?tools=web_search_exa";
          enabled = true;
          oauth = false;
        };
        context7 = {
          type = "remote";
          url = "https://mcp.context7.com/mcp";
          enabled = true;
          oauth = false;
        };
        grep_app = {
          type = "remote";
          url = "https://mcp.grep.app";
          enabled = true;
          oauth = false;
        };
      } // localMcp;
    };
    oh-my-opencode = {
      enable = true;
      settings = {
        google_auth = true;
      };
    };
  };
}
