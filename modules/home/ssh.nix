_: {
  programs.ssh = {
    enable = true;
    matchBlocks = {
      "github.com" = {
        hostname = "ssh.github.com";
        port = 443;
        user = "git";
        identitiesOnly = true;
        extraOptions.AddressFamily = "inet";
        identityFile = [ "~/.ssh/id_ed25519" ];
      };
      "gitee.com" = {
        hostname = "ssh.gitee.com";
        port = 443;
        user = "git";
        identitiesOnly = true;
        extraOptions.AddressFamily = "inet";
        identityFile = [ "~/.ssh/id_ed25519" ];
      };
    };
  };

  services.ssh-agent.enable = true;
}
