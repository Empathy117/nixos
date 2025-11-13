# home/home.nix
{
  pkgs,
  pkgsUnstable,
  ...
}: {
  home.stateVersion = "25.05";

  home.packages = with pkgs; [
    vim
    wget
    python314
    fastfetch
    openssl
    nixd
    direnv
    statix
    deadnix
    alejandra
    pkgsUnstable.codex
  ];

  imports = [
    ../common/keygen.nix
    ./vscode
  ];

  programs.git = {
    enable = true;

    extraConfig = {
      user.name = "empathy";
      user.email = "empathyyiyiqi@gmail.com";

      net.defaultAddressFamily = "inet";

      #url."https://gh-proxy.com/https://github.com/".insteadOf = "https://github.com/";
      url."ssh://git@github.com/".insteadOf = "https://github.com/";
      url."ssh://git@gitee.com/".insteadOf = "https://gitee.com/";

      core.sshCommand = "ssh -4";
    };
    #settings = {
    # net = {
    #  defaultAddressFamily = "inet";
    # };

    #url."https://gh-proxy.com/https://github.com/" = {
    # insteadOf = "https://github.com/";
    #};
    #};
  };

  programs.ssh = {
    enable = true;

    matchBlocks."github.com" = {
      hostname = "ssh.github.com";
      port = 443;
      user = "git";
      identitiesOnly = true;

      extraOptions = {AddressFamily = "inet";};
      identityFile = ["~/.ssh/id_ed25519"];
    };
    matchBlocks."gitee.com" = {
      hostname = "ssh.gitee.com";
      port = 443;
      user = "git";
      identitiesOnly = true;

      extraOptions = {AddressFamily = "inet";};
      identityFile = ["~/.ssh/id_ed25519"];
    };
  };
  services.ssh-agent.enable = true;

}
