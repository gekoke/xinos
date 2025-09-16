{ craneLib, pkgs, release, ... }: let
  # The system package. This package provides the kernel and other components
  # of the system, all sharing a Cargo.lock file and a Cargo workspace.
  # You don't have to do this with your project, you can also package all the
  # components of your system separately, as showcased in the C template.
  system = pkgs.callPackage ./. { inherit release craneLib; };
in {
  build.label = "xinos";
  boot.loader.devices = [ "disk" ];
  # Timeout in seconds that Limine will use before automatically booting.
  boot.loader.timeout = 3;
  boot.loader.limine.enable = true;
  boot.entry."Xinos" = {
    # We use the Limine boot protocol.
    protocol = "limine";
    # Path to the kernel to boot. boot():/ represents the partition on which limine.conf is located.
    kernelPath = "boot():/boot/kernel";
  };

  # The path where the ESP will be mounted. By default, limine.conf and the EFI
  # executables are placed there.
  # In nixstrap, paths are relative to the disk root and don't need the root /
  # This option defaults to "boot", as that is a common ESP mountpoint.
  boot.efiSysMountPoint = "";

  # This copies the kernel from the system build, and places it in /boot/kernel
  file."boot/kernel".source = "${system.kernel}/bin/kernel";

  # The image definition. This uses the same format as disko images, and
  # nixstrap internally uses a fork of disko to create and format these images.
  image.disk = {
    type = "disk";
    imageSize = "16M";
    content = {
      type = "gpt";
      partitions.ESP = {
        type = "EF00";
        size = "100%";
        content = {
          type = "filesystem";
          format = "vfat";
          mountpoint = "/";
        };
      };
    };
  };
}
