# Xinos

## Building

Build a bootable disk image for `x86_64`:
```sh
nix build .#nixstrapConfigurations.x86_64-disk.config.build.artifacts
```

The resulting image will be available in `result/disk`.

## Development

For development, it's much faster to build the kernel outside of the Nix sandbox and copy it
into an existing bootloader:

```sh
direnv allow
dev
```

This will:

- Build the bootloader without the kernel (this is slow the first time, but is cached after)
- Mount the bootloader
- Build the kernel
- Copy the kernel binary into the mount
- Run QEMU on the device the file was placed into

Though these actions happen outside of the Nix sandbox, the build environment
is sourced using Nix and therefore still has strong reproducibility guarantees.
