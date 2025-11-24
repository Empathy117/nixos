{ ... }:
{
  # 公共 Git 用户的 SSH 公钥配置
  # 在这里集中管理所有可以通过 git@HOST 访问 /srv/git 的用户 key
  users.users.git.openssh.authorizedKeys.keys = [
    # 现有的两把 key（来自 devbox 配置），按需追加同事 key
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJrO/0OgAxwADiPm93IrC9Y87Kfc6pr1OhkbD+bF77ge empathy@DyldadeMacBook-Pro.local"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPXam0l+NkYNEisRt9nYAIR/cfCpMONzX+tVJpU7TjJm empathyyiyiqi@gmail.com"
  ];
}

