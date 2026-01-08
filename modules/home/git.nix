_: {
  programs.git = {
    enable = true;
    settings = {
      core.sshCommand = "ssh -4";
      net.defaultAddressFamily = "inet";
      url."ssh://git@github.com/".insteadOf = "https://github.com/";
      # url."https://gh-proxy.com/https://github.com/".insteadOf = "https://github.com/";
      url."ssh://git@gitee.com/".insteadOf = "https://gitee.com/";
      user.email = "empathyyiyiqi@gmail.com";
      user.name = "empathy";

      safe = {
        directory = [
          "/srv/git/bsc-service.git"
          "/srv/git/mdm-service.git"
          "/srv/git/bms-service.git"
          "/srv/git/bsc-frontend.git"
          "/srv/git/mdm-frontend.git"
          "/srv/git/bms-frontend.git"
          "/srv/git/portal-frontend.git"
          "/srv/git/rmp-service.git"
          "/srv/git/oms-service.git"
          "/srv/git/wms-service.git"
          "/srv/git/rmp-frontend.git"
          "/srv/git/oms-frontend.git"
          "/srv/git/wms-frontend.git"
        ];
      };
    };
  };
}
