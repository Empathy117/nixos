# home/home.nix
{
  lib,
  pkgs,
  pkgsUnstable,
  ...
}:
{
  home.stateVersion = "25.05";

  home.packages =
    (with pkgs; [
      vim
      wget
      (if pkgs ? python314 then pkgs.python314 else pkgs.python3)
      fastfetch
      openssl
      nixd
      direnv
      statix
      deadnix
      nixfmt-rfc-style
    ])
    ++ lib.optional (pkgsUnstable ? codex && lib.meta.availableOn pkgs.stdenv.hostPlatform pkgsUnstable.codex)
      pkgsUnstable.codex;

  imports = [
    ../common/keygen.nix
    ../modules/vscode/base.nix
  ];

  nixpkgs.config.allowUnfree = true;

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

      extraOptions = {
        AddressFamily = "inet";
      };
      identityFile = [ "~/.ssh/id_ed25519" ];
    };
    matchBlocks."gitee.com" = {
      hostname = "ssh.gitee.com";
      port = 443;
      user = "git";
      identitiesOnly = true;

      extraOptions = {
        AddressFamily = "inet";
      };
      identityFile = [ "~/.ssh/id_ed25519" ];
    };
  };
  services.ssh-agent.enable = true;

}
