{ ... }:
{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    enableAutosuggestions = true;
    enableSyntaxHighlighting = true;

    history.size = 10000;

    initExtraFirst = ''
      setopt SHARE_HISTORY HIST_IGNORE_DUPS HIST_IGNORE_SPACE EXTENDED_HISTORY
      HISTFILESIZE=10000
    '';

    initExtra = ''
      setproxy() {
        local host=''${1:-127.0.0.1}
        local port=''${2:-7890}
        export http_proxy="http://''${host}:''${port}"
        export https_proxy="http://''${host}:''${port}"
        export all_proxy="socks5://''${host}:''${port}"
        export HTTP_PROXY="$http_proxy"
        export HTTPS_PROXY="$https_proxy"
        export ALL_PROXY="$all_proxy"
        echo "Proxy set to ''${host}:''${port}"
      }
      unsetproxy() {
        unset http_proxy https_proxy all_proxy HTTP_PROXY HTTPS_PROXY ALL_PROXY
        echo "Proxy variables cleared"
      }
    '';
  };
}
