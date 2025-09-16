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
          packages = [
            pkgs.rustToolchain
            pkgs.cargo-watch
            (pkgs.writeShellApplication {
              name = "dev";
              text = ''
                ${pkgs.nix}/bin/nix build .#nixstrapConfigurations.x86_64-hdd.config.build.artifacts
                cp ./result/disk ./disk.bin
                rm -rf ./result
                chmod +w ./disk.bin
                ${pkgs.qemu}/bin/qemu-system-x86_64 -bios ${pkgs.OVMF.fd}/FV/OVMF.fd ./disk.bin
              '';
            })
          ];

          env = {
            # Required by rust-analyzer
            RUST_SRC_PATH = "${pkgs.rustToolchain}/lib/rustlib/src/rust/library";
          };
        };
      });

      nixstrapConfigurations = {
        x86_64-hdd = mkConfiguration "x86_64-elf" false;
      };
    };
}
