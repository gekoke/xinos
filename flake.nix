{
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

  outputs =
    {
      self,
      crane,
      nixpkgs,
      nixstrap,
      rust-overlay,
    }:
    let
      lib = nixpkgs.lib;
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forEachSupportedSystem =
        f:
        lib.genAttrs supportedSystems (
          system:
          f {
            pkgs = import nixpkgs {
              inherit system;
              overlays = [
                rust-overlay.overlays.default
                self.overlays.default
              ];
            };
          }
        );
      mkConfiguration =
        {
          cross,
          withKernel,
          release,
        }:
        nixstrap.lib.nixstrapConfiguration {
          modules = [
            (
              { pkgs, ... }:
              {
                nixpkgs.crossSystem.config = cross;
                nixpkgs.overlays = [
                  rust-overlay.overlays.default
                  self.overlays.default
                ];
                _module.args.craneLib = (crane.mkLib pkgs.buildPackages).overrideToolchain (p: p.rustToolchain);
              }
            )
            ./bootstrap.nix
          ];
          extraSpecialArgs = {
            inherit release withKernel;
          };
        };
    in
    {
      overlays.default = final: prev: {
        rustToolchain = prev.rust-bin.fromRustupToolchainFile ./rust-toolchain.toml;
      };

      devShells = forEachSupportedSystem (
        { pkgs }:
        {
          default = pkgs.mkShell {
            packages = [
              pkgs.rustToolchain
              pkgs.cargo-watch
              (pkgs.writeShellApplication {
                name = "qemuefi";
                text = ''
                  ${pkgs.qemu}/bin/qemu-system-x86_64 -bios ${pkgs.OVMF.fd}/FV/OVMF.fd "$@"
                '';
              })

              (pkgs.writeShellApplication {
                name = "setup";
                text = ''
                  if [ ! -f ".allow_setup" ]; then
                      echo "no .allow_setup file in $(pwd) - refusing to run"
                      exit 77
                  fi
                  if [ -f ".loopdevice.txt" ]; then
                      echo ".loopdevice.txt file in $(pwd) - refusing to run"
                      exit 77
                  fi

                  set -x

                  cp ${self.nixstrapConfigurations.limine-x86_64-disk.config.build.artifacts}/disk ./disk
                  chmod +w ./disk
                  DEVICE=$(sudo losetup --show --partscan --find ./disk)
                  echo -n "$DEVICE" > .loopdevice.txt
                  mkdir -p mnt
                  sudo mount -o sync "''${DEVICE}p1" mnt
                  rm -rf disk
                '';
              })

              (pkgs.writeShellApplication {
                name = "inject";
                text = ''
                  if [ ! -f ".allow_setup" ]; then
                      echo "no .allow_setup file in $(pwd) - refusing to run"
                      exit 77
                  fi
                  if [ ! -f ".loopdevice.txt" ]; then
                      echo "no .loopdevice.txt file in $(pwd) - refusing to run"
                      exit 77
                  fi

                  set -x

                  cargo build
                  sudo mkdir -p ./mnt/boot
                  sudo cp target/target/debug/kernel ./mnt/boot
                '';
              })

              (pkgs.writeShellApplication {
                name = "dev";
                text = ''
                  if [ ! -f ".allow_setup" ]; then
                      echo "no .allow_setup file in $(pwd) - refusing to run"
                      exit 77
                  fi
                  if [ -f ".loopdevice.txt" ]; then
                      set -x
                      teardown
                  fi
                  set -x

                  setup
                  inject
                  sudo qemuefi -drive file="$(cat .loopdevice.txt)p1",format=raw 
                '';
              })

              (pkgs.writeShellApplication {
                name = "teardown";
                text = ''
                  if [ ! -f ".allow_setup" ]; then
                      echo "no .allow_setup file in $(pwd) - refusing to run"
                      exit 77
                  fi
                  if [ ! -f ".loopdevice.txt" ]; then
                      echo "no .loopdevice.txt file in $(pwd) - refusing to run"
                      exit 77
                  fi

                  set -x

                  sudo umount mnt
                  sudo losetup --detach "$(cat .loopdevice.txt)"
                  rmdir mnt
                  rm .loopdevice.txt
                '';
              })
            ];

            env = {
              # Required by rust-analyzer
              RUST_SRC_PATH = "${pkgs.rustToolchain}/lib/rustlib/src/rust/library";
            };
          };
        }
      );

      nixstrapConfigurations = {
        xinos-x86_64-disk = mkConfiguration {
          cross = "x86_64-elf";
          withKernel = true;
          release = false;
        };
        limine-x86_64-disk = mkConfiguration {
          cross = "x86_64-elf";
          withKernel = false;
          release = false;
        };
      };
    };
}
