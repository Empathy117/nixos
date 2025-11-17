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
}
