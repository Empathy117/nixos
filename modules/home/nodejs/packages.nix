# Node.js 包配置
# 在这里配置要安装的全局包
{
  programs.nodejs = {
    # 按需下载（用 pnpx，首次慢，之后快）
    globalPackages = [
      "cxresume"
    ];
    
    # 真正安装（占空间，但最快）
    installedPackages = [
      # "typescript"
      # "prettier"
    ];
  };
}
