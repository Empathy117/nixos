# modules/home/direnv.nix
# direnv: 自动加载项目开发环境的工具
_: {
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true; # 缓存优化
    enableZshIntegration = true;
  };
}
