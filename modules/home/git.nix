_: {
  programs.git = {
    enable = true;
    settings = {
      core.sshCommand = "ssh -4";
      net.defaultAddressFamily = "inet";
      url."ssh://git@github.com/".insteadOf = "https://github.com/";
      url."ssh://git@gitee.com/".insteadOf = "https://gitee.com/";
      user.email = "empathyyiyiqi@gmail.com";
      user.name = "Empathy117";
    };
  };
}
