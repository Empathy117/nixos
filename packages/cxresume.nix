# 优雅的方式：使用 npmlock2nix 或直接用 runCommand
{ pkgs }:

# 方案 1: 最简洁 - 直接包装 npm install
pkgs.runCommand "cxresume" {
  buildInputs = [ pkgs.nodejs ];
} ''
  mkdir -p $out/bin
  export HOME=$TMPDIR
  ${pkgs.nodejs}/bin/npm install -g --prefix $out cxresume
  # 创建包装脚本
  cat > $out/bin/cxresume <<EOF
  #!${pkgs.bash}/bin/bash
  exec ${pkgs.nodejs}/bin/node $out/lib/node_modules/cxresume/bin/cxresume.js "\$@"
  EOF
  chmod +x $out/bin/cxresume
''

# 方案 2: 如果你想更标准，用这个
# pkgs.buildNpmPackage rec {
#   pname = "cxresume";
#   version = "1.0.0";
#   
#   src = pkgs.fetchurl {
#     url = "https://registry.npmjs.org/cxresume/-/cxresume-${version}.tgz";
#     hash = "sha256-AAAA..."; # nix-prefetch-url 获取
#   };
#   
#   npmDepsHash = "sha256-AAAA...";
#   dontNpmBuild = true;
# }
