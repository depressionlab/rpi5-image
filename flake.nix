{
  inputs.nixpkgs.url = "https://channels.nixos.org/nixpkgs-unstable/nixexprs.tar.zst";
  inputs.nixos-hardware.url = "github:NixOS/nixos-hardware/master";
  inputs.nixos-hardware.inputs.nixpkgs.follows = "nixpkgs";

  outputs = { self, nixpkgs, nixos-hardware, ... }:
  let
    system = "aarch64-linux";
    commonModules = [
      nixos-hardware.nixosModules.raspberry-pi-5
      ./configuration.nix
      ./modules/uctronics-display.nix
      ./modules/embed-flake.nix
    ];
  in
  {
    nixosConfigurations.rpi5 = nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = { inherit self; };
      modules = commonModules;
    };

    nixosConfigurations.rpi5-sd-image = nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = { inherit self; };
      modules = commonModules ++ [
        "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"
        ({ lib, ... }: {
          hardware.raspberry-pi.firmware.uboot.enable = true;
          boot.supportedFilesystems.zfs = lib.mkForce false;
        })
      ];
    };
  };
}
