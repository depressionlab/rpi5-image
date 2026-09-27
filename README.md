# CS Seminar RPI5 NixOS flake

## Prior to building

Edit the top of `configuration.nix`:

- `sshPublicKeys`: put your real public key(s) in here.
- `username`: change it to your username
- `useUEFI`: generally you want this to be `false`.
