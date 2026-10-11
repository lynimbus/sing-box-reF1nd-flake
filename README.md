# sing-box-reF1nd flake

Packages [reF1nd/sing-box](https://github.com/reF1nd/sing-box) from the
`reF1nd-testing` branch for `x86_64-linux` and `aarch64-linux`.
`flake.lock` pins the source commit and Go dependencies use a fixed vendor hash.

## Build

```console
nix build .#default
./result/bin/sing-box version
```

The named package `packages.<system>.sing-box-reF1nd` is also available.
The executable remains `sing-box`; shell completions, systemd units and
polkit/D-Bus configuration are included.
Build tags include the upstream defaults plus `with_gvisor` and
`with_ebpf`. The experimental eBPF inbound and `sing-box tools ebpf` commands
are included; using them requires appropriate kernel support and privileges.
Naive outbound is enabled with `with_naive_outbound` and `with_purego`.
The matching architecture's prebuilt Cronet shared library is bundled and its
dynamic dependencies are patched for Nix; no separate Chromium build is needed.

## Use in Another Flake

Add this repository as a flake input named `sing-box-reF1nd`, then select
`inputs.sing-box-reF1nd.packages.${pkgs.system}.default` as the package,
for example with `services.sing-box.package` on NixOS.

`overlays.default` exposes `pkgs.sing-box-reF1nd` and the compatibility alias
`pkgs.sing-box-unstable`.

## Updates

The update workflow checks `reF1nd-testing` daily, updates only `sing-box-src`,
refreshes the Go vendor hash when needed, and builds before committing.
It retains the existing Cachix configuration; uploads require the repository's
`CACHIX_AUTH_TOKEN` secret.

To update locally, run `nix flake update sing-box-src`, set the package version
to `unstable-YYYY-MM-DD` using the locked commit's UTC date, and run `nix build`.
If Nix reports a vendor hash mismatch, replace `vendorHash` with its `got:` hash
and build again.

The packaged source is licensed under GPL-3.0-or-later.
