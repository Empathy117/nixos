{ lib, ... }:
let
  registryMirrors = [
    "https://docker.mirrors.ustc.edu.cn/"
    "https://docker.mirrors.sjtug.sjtu.edu.cn/"
    "https://docker.tuna.tsinghua.edu.cn/"
    "https://docker.nju.edu.cn/"
    "https://registry.cn-hangzhou.aliyuncs.com/"
  ];
in
{
  virtualisation.docker = {
    enable = lib.mkDefault true;
    daemon.settings."registry-mirrors" = registryMirrors;
  };

  # Force docker daemon traffic through the local proxy so pulls work even when
  # the system-wide route is restricted.
  systemd.services.docker.environment = {
    HTTP_PROXY = "http://127.0.0.1:7890";
    HTTPS_PROXY = "http://127.0.0.1:7890";
    NO_PROXY = "localhost,127.0.0.1";
  };
}
