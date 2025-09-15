{
  description = "Template for a Limine-compliant kernel in Rust using nixstrap.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixstrap = {
      url = "sourcehut:~asya/nixstrap";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    crane.url = "github:ipetkov/crane";
  };

  outputs = { self, crane, nixpkgs, nixstrap, rust-overlay }:
    let
      lib = nixpkgs.lib;
      supportedSystems = [ "x86_64-linux" "aarch64-linux" ];
      forEachSupportedSystem = f: lib.genAttrs supportedSystems (system: f {
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ rust-overlay.overlays.default self.overlays.default ];
        };
      });
      mkConfiguration = cross: release: nixstrap.lib.nixstrapConfiguration {
        modules = [
          ({ pkgs, ... }: {
            nixpkgs.crossSystem.config = cross;
            nixpkgs.overlays = [ rust-overlay.overlays.default self.overlays.default ];
            _module.args.craneLib = (crane.mkLib pkgs.buildPackages).overrideToolchain (p: p.rustToolchain);
          })
          ./bootstrap.nix
        ];
        extraSpecialArgs.release = release;
      };
    in
    {
      overlays.default = final: prev: {
        rustToolchain =
          let
            rust = prev.rust-bin;
          in
          if builtins.pathExists ./rust-toolchain.toml then
            rust.fromRustupToolchainFile ./rust-toolchain.toml
          else if builtins.pathExists ./rust-toolchain then
            rust.fromRustupToolchainFile ./rust-toolchain
          else
            rust.stable.latest.default.override {
              extensions = [ "rust-src" "rustfmt" ];
            };
      };

      devShells = forEachSupportedSystem ({ pkgs }: {
        default = pkgs.mkShell {
          packages = with pkgs; [
            rustToolchain
            openssl
            pkg-config
            cargo-deny
            cargo-edit
            cargo-watch
            (pkgs.writeShellScriptBin "qemu-system-x86_64-uefi" ''
                ${pkgs.qemu}/bin/qemu-system-x86_64 -bios ${pkgs.OVMF.fd}/FV/OVMF.fd "$@"
            '')
            (pkgs.writeShellScriptBin "dev" ''
                ${pkgs.qemu}/bin/qemu-system-x86_64 -drive format=raw,file=${self.nixstrapConfigurations.x86_64-hdd.config.build.artifacts}/disk -bios ${pkgs.OVMF.fd}/FV/OVMF.fd 
            '')
          ];

          env = {
            # Required by rust-analyzer
            RUST_SRC_PATH = "${pkgs.rustToolchain}/lib/rustlib/src/rust/library";
          };
        };
      });

      nixstrapConfigurations = {
        # FIXME: ISO configurations
        # FIXME: loongarch64
        # FIXME: bios
        x86_64-hdd = mkConfiguration "x86_64-elf" false;
        aarch64-hdd = mkConfiguration "aarch64-elf" false;
        riscv64-hdd = mkConfiguration "riscv64-elf" false;
        x86_64-release-hdd = mkConfiguration "x86_64-elf" true;
        aarch64-release-hdd = mkConfiguration "aarch64-elf" true;
        riscv64-release-hdd = mkConfiguration "riscv64-elf" true;
      };
    };
}
