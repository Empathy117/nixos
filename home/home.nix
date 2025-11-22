# home/home.nix
#
# Home Manager 主配置 - 用户环境的统一入口
#
# 此文件聚合所有用户级模块，提供跨主机一致的 CLI 体验
# 适用场景：
# - NixOS 系统（通过 nixosConfigurations 集成）
# - 非 NixOS 系统（通过 homeConfigurations 独立使用）
#
# 设计原则：
# - 只包含"任何地方都需要"的配置
# - 主机特定的配置应该在 flake.nix 的 homeModules 中额外添加
# - 保持模块化，每个功能独立成文件
_: {
  # Home Manager 版本锚点
  home.stateVersion = "25.05";

  imports = [
    # CLI 工具和终端增强
    ../modules/home/cli.nix
    
    # Git 配置（用户信息、别名、代理）
    ../modules/home/git.nix
    
    # SSH 配置（GitHub/Gitee 等）
    ../modules/home/ssh.nix
    
    # SSH 密钥自动生成
    ../modules/home/ssh-key.nix
    
    # Neovim 配置（通过 nixvim）
    ../modules/home/nixvim.nix
    
    # Zsh 配置（历史、补全、高亮）
    ../modules/home/zsh.nix
    
    # Node.js 开发环境
    ./modules/nodejs.nix
  ];
}
