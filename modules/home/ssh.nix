{ pkgs, ... }:
{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings = {
      "github.com" = {
        HostName = "ssh.github.com";
        Port = 443;
        User = "git";
        IdentitiesOnly = true;
        AddressFamily = "inet";
        IdentityFile = [ "~/.ssh/id_ed25519" ];
      };
      "gitee.com" = {
        HostName = "ssh.gitee.com";
        Port = 443;
        User = "git";
        IdentitiesOnly = true;
        AddressFamily = "inet";
        IdentityFile = [ "~/.ssh/id_ed25519" ];
      };
    };
  };

  services.ssh-agent.enable = pkgs.stdenv.hostPlatform.isLinux;
}
