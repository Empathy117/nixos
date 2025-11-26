{
  pkgs,
  config,
  ...
}:
let
  aic8800d80-driver = config.boot.kernelPackages.callPackage ./aic8800d80-driver.nix { };
in
{
  imports = [
    ./hardware-configuration.nix
  ];
  hardware.firmware = [
    pkgs.linux-firmware
    aic8800d80-driver
  ];
  networking.networkmanager.enable = true;
  boot.kernelPackages = pkgs.linuxPackages;
  boot.extraModulePackages = [
    aic8800d80-driver
  ];

  environment.systemPackages = with pkgs; [
    usbutils
    pciutils
    iw
    wirelesstools
    usb-modeswitch
    gcc
    gnumake
    config.boot.kernelPackages.kernel.dev
    wpa_supplicant
  ];

  # 允许运行通用 Linux 动态链接二进制（如 JetBrains Gateway 下载的 remote-dev-server）
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [ stdenv.cc.cc ];
  };

  # Journald放在机械盘上
  services.journald = {
    storage = "persistent";
    extraConfig = ''
      SystemMaxUse=10G
      RuntimeMaxUse=1G  # 限制在 /var/log/journal 的临时日志大小
      StateDirectory=/data/log
    '';
  };

  services.mihomo = {
    enable = true;
    configFile = "/etc/mihomo/config.yaml";
    tunMode = true;
  };
  # environment.etc."mihomo/config.yaml".text = ''
  #   # placeholder – scp your real config to /etc/mihomo/config.yaml
  # '';
  environment.etc."mihomo/config.yaml".source = "/home/empathy/.mihomo/config.yaml";
  services.mihomo.webui = pkgs.metacubexd;

  hardware.enableRedistributableFirmware = true;
  services.udev.packages = [ pkgs.usb-modeswitch-data ];
  system.activationScripts.auc8800D80-firmware = ''
    mkdir -p /lib
    ln -sfn /run/current-system/firmware /lib/firmware
  '';
  services.udev.extraRules = ''
    SUBSYSTEM=="usb", ATTR{idVendor}=="a69c", ATTR{idProduct}=="5725", RUN+="${pkgs.usb-modeswitch}/bin/usb_modeswitch -v a69c -p 5725 -K"
  '';

  networking.firewall = {
    enable = true; # 如果原来就是 true 可不写
    allowedTCPPorts = [
      80   # nginx
      7890 # mixed port
      9090 # mihomo 控制端（Web UI）
      8081 # nexus
      5326 # dameng
      6379 # redis
      2181 # zookeeper
      9092 # kafka
      8848 # nacos
      9848 # nacos
      9849 # nacos
      9000 # minio
      9001 # minio
      8896 # bsc-service
      8083 # mdm-service
      8088 # bms-service
      8881 # oms-service
      8082 # rmp-service
      8084 # wms-service
    ];
    # 开启tunmode
    trustedInterfaces = [
      "mihomo"
      "Meta"
    ];
    checkReversePath = "loose"; # 关键
    # allowedUDPPorts = [ 7890 ];  # 需要 UDP 时再开启
  };

  # Yoohoo 应用服务（本机开发 / 测试）
  services.yoohoo = {
    enable = true;
    baseDir = "/srv/yoohoo";

    bsc.instances = {
      main = {
        enable = true;
        # 部署工作目录来自 bsc-service 裸仓库
        workingDir = "/srv/yoohoo/bsc-service";
        profile = "local";
      };
    };

    mdm.instances = {
      main = {
        enable = true;
        workingDir = "/srv/yoohoo/mdm-service";
        profile = "local";
      };
    };

    bms.instances = {
      main = {
        enable = true;
        workingDir = "/srv/yoohoo/bms-service";
        profile = "local";
      };
    };

    rmp.instances = {
      main = {
        enable = true;
        workingDir = "/srv/yoohoo/rmp-service";
        profile = "local";
      };
    };

    oms.instances = {
      main = {
        enable = true;
        workingDir = "/srv/yoohoo/oms-service";
        profile = "local";
      };
    };

    wms.instances = {
      main = {
        enable = true;
        workingDir = "/srv/yoohoo/wms-service";
        profile = "local";
      };
    };
  };

  # 简易 CI/CD：本机多个裸仓库 + 自动部署到各自工作目录
  services.yoohooDeploy = {
    enable = true;
    repoDir = "/srv/git";
    user = "git";
    group = "git";

    instances = {
      # 后端服务仓库
      bsc-service = {
        repoName = "bsc-service.git";
        workTree = "/srv/yoohoo/bsc-service";
        branch = "master";
        allowedPushers = [ "empathy" ];
        postCheckoutCmd = ''
          systemctl restart yoohoo-bsc-main
        '';
      };

      mdm-service = {
        repoName = "mdm-service.git";
        workTree = "/srv/yoohoo/mdm-service";
        branch = "master";
        allowedPushers = [ "empathy" ];
        postCheckoutCmd = ''
          systemctl restart yoohoo-mdm-main
        '';
      };

      bms-service = {
        repoName = "bms-service.git";
        workTree = "/srv/yoohoo/bms-service";
        branch = "master";
        allowedPushers = [ "empathy" ];
        postCheckoutCmd = ''
          systemctl restart yoohoo-bms-main
        '';
      };

      rmp-service = {
        repoName = "rmp-service.git";
        workTree = "/srv/yoohoo/rmp-service";
        branch = "master";
        allowedPushers = [ "empathy" ];
        postCheckoutCmd = ''
          systemctl restart yoohoo-rmp-main
        '';
      };

      oms-service = {
        repoName = "oms-service.git";
        workTree = "/srv/yoohoo/oms-service";
        branch = "master";
        allowedPushers = [ "empathy" ];
        postCheckoutCmd = ''
          systemctl restart yoohoo-oms-main
        '';
      };

      wms-service = {
        repoName = "wms-service.git";
        workTree = "/srv/yoohoo/wms-service";
        branch = "master";
        allowedPushers = [ "empathy" ];
        postCheckoutCmd = ''
          systemctl restart yoohoo-wms-main
        '';
      };

      # 前端仓库：build 后拷贝到 /srv/www 下，供 nginx 使用
      bsc-frontend = {
        repoName = "bsc-frontend.git";
        workTree = "/srv/yoohoo/bsc-frontend";
        branch = "master";
        allowedPushers = [ "empathy" ];
        postCheckoutCmd = ''
          ${pkgs.pnpm}/bin/pnpm install --frozen-lockfile || ${pkgs.pnpm}/bin/pnpm install
          ${pkgs.pnpm}/bin/pnpm build:production-no-ts

          mkdir -p /srv/www
          rm -rf /srv/www/febsc
          cp -r /srv/yoohoo/bsc-frontend/febsc /srv/www/
        '';
      };

      mdm-frontend = {
        repoName = "mdm-frontend.git";
        workTree = "/srv/yoohoo/mdm-frontend";
        branch = "master";
        allowedPushers = [ "empathy" ];
        postCheckoutCmd = ''
          ${pkgs.pnpm}/bin/pnpm install --frozen-lockfile || ${pkgs.pnpm}/bin/pnpm install
          ${pkgs.pnpm}/bin/pnpm build:production-no-ts

          mkdir -p /srv/www
          rm -rf /srv/www/femdm
          cp -r /srv/yoohoo/mdm-frontend/femdm /srv/www/
        '';
      };

      bms-frontend = {
        repoName = "bms-frontend.git";
        workTree = "/srv/yoohoo/bms-frontend";
        branch = "master";
        allowedPushers = [ "empathy" ];
        postCheckoutCmd = ''
          ${pkgs.pnpm}/bin/pnpm install --frozen-lockfile || ${pkgs.pnpm}/bin/pnpm install
          ${pkgs.pnpm}/bin/pnpm build:production-no-ts

          mkdir -p /srv/www
          rm -rf /srv/www/febms
          cp -r /srv/yoohoo/bms-frontend/dist /srv/www/febms
        '';
      };

      portal-frontend = {
        repoName = "portal-frontend.git";
        workTree = "/srv/yoohoo/portal-frontend";
        branch = "master";
        allowedPushers = [ "empathy" ];
        postCheckoutCmd = ''
          ${pkgs.pnpm}/bin/pnpm install --frozen-lockfile || ${pkgs.pnpm}/bin/pnpm install
          ${pkgs.pnpm}/bin/pnpm build:production-no-ts

          mkdir -p /srv/www
          rm -rf /srv/www/portal
          cp -r /srv/yoohoo/portal-frontend/portal /srv/www/portal
        '';
      };

      # 新增前端仓库：构建后拷贝到 /srv/www 对应目录
      rmp-frontend = {
        repoName = "rmp-frontend.git";
        workTree = "/srv/yoohoo/rmp-frontend";
        branch = "master";
        allowedPushers = [ "empathy" ];
        postCheckoutCmd = ''
          ${pkgs.pnpm}/bin/pnpm install --frozen-lockfile || ${pkgs.pnpm}/bin/pnpm install
          ${pkgs.pnpm}/bin/pnpm build:production-no-ts

          mkdir -p /srv/www
          rm -rf /srv/www/fermp
          cp -r /srv/yoohoo/rmp-frontend/fermp /srv/www/
        '';
      };

      oms-frontend = {
        repoName = "oms-frontend.git";
        workTree = "/srv/yoohoo/oms-frontend";
        branch = "master";
        allowedPushers = [ "empathy" ];
        postCheckoutCmd = ''
          ${pkgs.pnpm}/bin/pnpm install --frozen-lockfile || ${pkgs.pnpm}/bin/pnpm install
          ${pkgs.pnpm}/bin/pnpm build:production-no-ts

          mkdir -p /srv/www
          rm -rf /srv/www/feoms
          cp -r /srv/yoohoo/oms-frontend/dist /srv/www/feoms
        '';
      };

      wms-frontend = {
        repoName = "wms-frontend.git";
        workTree = "/srv/yoohoo/wms-frontend";
        branch = "master";
        allowedPushers = [ "empathy" ];
        postCheckoutCmd = ''
          ${pkgs.pnpm}/bin/pnpm install --frozen-lockfile || ${pkgs.pnpm}/bin/pnpm install
          ${pkgs.pnpm}/bin/pnpm build:production-no-ts

          mkdir -p /srv/www
          rm -rf /srv/www/fewms
          cp -r /srv/yoohoo/wms-frontend/dist /srv/www/fewms
        '';
      };
    };
  };

  # Nginx 统一入口，代理各个后端与前端静态资源
  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    recommendedGzipSettings = true;

    virtualHosts."yoohoo" = {
      listen = [
        {
          addr = "0.0.0.0";
          port = 80;
        }
      ];
      serverName = "172.16.10.126";
      root = "/srv/www";

      # 门户前端（portal-frontend），build 输出到 /srv/www/portal
      locations."/".extraConfig = ''
        try_files /portal/index.html =404;
      '';

      locations."/login".extraConfig = ''
        try_files $uri $uri/ /portal/index.html;
      '';

      # 门户静态资源
      locations."/assets/".extraConfig = ''
        alias /srv/www/portal/assets/;
      '';

      # 业务前端静态资源
      locations."/febsc".extraConfig = ''
        return 301 /febsc/;
      '';
      locations."/febsc/".extraConfig = ''
        try_files $uri $uri/ /febsc/index.html;
      '';

      locations."/femdm".extraConfig = ''
        return 301 /femdm/;
      '';
      locations."/femdm/".extraConfig = ''
        try_files $uri $uri/ /femdm/index.html;
      '';

      locations."/febms".extraConfig = ''
        return 301 /febms/;
      '';
      locations."/febms/".extraConfig = ''
        try_files $uri $uri/ /febms/index.html;
      '';

      # 新增前端入口
      locations."/fermp".extraConfig = ''
        return 301 /fermp/;
      '';
      locations."/fermp/".extraConfig = ''
        try_files $uri $uri/ /fermp/index.html;
      '';

      locations."/feoms".extraConfig = ''
        return 301 /feoms/;
      '';
      locations."/feoms/".extraConfig = ''
        try_files $uri $uri/ /feoms/index.html;
      '';

      locations."/fewms".extraConfig = ''
        return 301 /fewms/;
      '';
      locations."/fewms/".extraConfig = ''
        try_files $uri $uri/ /fewms/index.html;
      '';

      # 后端 API 代理
      locations."/bsc/".proxyPass = "http://127.0.0.1:8896";
      locations."/api/".proxyPass = "http://127.0.0.1:8896";
      locations."/mdm/".proxyPass = "http://127.0.0.1:8083";
      locations."/bms/".proxyPass = "http://127.0.0.1:8088";
      locations."/oms/".proxyPass = "http://127.0.0.1:8881";
      locations."/rmp/".proxyPass = "http://127.0.0.1:8082";
      locations."/wms/".proxyPass = "http://127.0.0.1:8084";
    };
  };

}
