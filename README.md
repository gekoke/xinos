# Xinos

## Building

Use the following command to build any of the configurations:
```
$ nix build .#nixstrapConfigurations.<configuration>.config.build.artifacts
```

For example, to build a bootable hdd image for x86_64, use the following command:
```
$ nix build .#nixstrapConfigurations.x86_64-hdd.config.build.artifacts
```

The resulting image will be available in `result/disk`.
