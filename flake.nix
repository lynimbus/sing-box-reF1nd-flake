{
  description = "sing-box-reF1nd flake tracking the reF1nd-testing branch";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    sing-box-src = {
      url = "github:reF1nd/sing-box/reF1nd-testing";
      flake = false;
    };
  };

  # 允许使用者自动获取你的二进制缓存
  nixConfig = {
    extra-substituters = [ "https://rxda-cache.cachix.org" ];
    extra-trusted-public-keys = [ "rxda-cache.cachix.org-1:LDGrYaB+dF7wh+uWMLjh5VsckzFnnCyGkMH1sKHN++g=" ];
  };

  outputs = inputs@{ self, nixpkgs, ... }:
    let
      # 支持 x86 和 ARM 架构
      systems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      packages = forAllSystems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.buildGoModule rec {
            pname = "sing-box-reF1nd";
            version = "unstable-2026-10-09";

            src = inputs.sing-box-src;

            # 多个实验特性用逗号隔开
            GOEXPERIMENT = "greenteagc,jsonv2";

            # 同时也需要在处理依赖阶段开启，否则 vendorHash 可能会在本地和 CI 环境不一致
            overrideModAttrs = (_: {
              GOEXPERIMENT = "greenteagc,jsonv2";
            });

            # 哈希会自动被 GitHub Action 里的脚本更新
            vendorHash = "sha256-c8BEbg2DTFqxV0FoZiR+F7Q5bIGGJiitPyIzfBoQ8m4=";

            # 包含所有增强特性
            tags = [
              "with_quic"
              "with_dhcp"
              "with_wireguard"
              "with_utls"
              "with_acme"
              "with_clash_api"
              "with_gvisor"
              "with_tailscale"
              "with_ebpf"
              "with_naive_outbound"
              "with_purego"
              "with_ccm"
              "with_ocm"
              "with_cloudflared"
              "with_usbip"
              "with_openvpn"
              "with_openconnect"
              "badlinkname"
              "tfogo_checklinkname0"
            ];

            subPackages = [ "cmd/sing-box" ];

            nativeBuildInputs = [ pkgs.installShellFiles pkgs.makeWrapper pkgs.autoPatchelfHook ];
            buildInputs = [ pkgs.stdenv.cc.cc.lib ];

            ldflags = [
              "-X github.com/sagernet/sing-box/constant.Version=reF1nd-${version}-${builtins.substring 0 12 inputs.sing-box-src.rev}"
            ];

            # 保持与官方包一致的收尾工作（补全脚本和服务文件）
            postInstall = ''
              installShellCompletion release/completions/sing-box.{bash,fish,zsh}

              install -Dm755 \
                vendor/github.com/sagernet/cronet-go/lib/linux_${if system == "x86_64-linux" then "amd64" else "arm64"}/libcronet.so \
                "$out/lib/sing-box/libcronet.so"
              wrapProgram "$out/bin/sing-box" \
                --prefix LD_LIBRARY_PATH : "$out/lib/sing-box"

              substituteInPlace release/config/sing-box{,@}.service \
                --replace-fail "/usr/bin/sing-box" "$out/bin/sing-box" \
                --replace-fail "/bin/kill" "${pkgs.coreutils}/bin/kill"
              install -Dm444 -t "$out/lib/systemd/system/" release/config/sing-box{,@}.service

              install -Dm444 release/config/sing-box.rules $out/share/polkit-1/rules.d/sing-box.rules
              install -Dm444 release/config/sing-box-split-dns.xml $out/share/dbus-1/system.d/sing-box-split-dns.conf
            '';
          };
          sing-box-reF1nd = self.packages.${system}.default;
        });

      # 提供 Overlay 选项，虽然你现在直接引用 packages，但留着是个好习惯
      overlays.default = final: prev: {
        sing-box-reF1nd = self.packages.${final.system}.default;
        sing-box-unstable = self.packages.${final.system}.default;
      };
    };
}
