{ lib, pkgs, inputs, ... }:
let
  ############################################################
  ## Edit these before building
  ############################################################

  useUEFI = false;
  username = "ethanb";
  hostname = "${username}s-rpi5";
  enableUctronicsDisplay = true;
  sshPublicKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBhvv6ptFp/eDiphCVjZdMWJJ2fvPSswz6XWVEKJLqTj"
  ];
  flakeInputs = lib.attrsets.filterAttrs (
    name: value: (value._type or null) == "flake" && name != "self"
  ) inputs;
in
{
  nixpkgs.flake.source = lib.modules.mkForce null;
  nix.registry = lib.attrsets.mapAttrs (_: flake: { inherit flake; }) flakeInputs;
  nix.nixPath = lib.attrsets.mapAttrsToList (k: v: "${k}=flake:${v.outPath}") flakeInputs;

  services.uctronicsDisplay.enable = enableUctronicsDisplay;

  boot.loader = lib.mkMerge [
    (lib.mkIf useUEFI {
      efi.canTouchEfiVariables = true;
      limine.enable = true;
      limine.efiSupport = true;
      limine.biosSupport = false;
      grub.enable = lib.mkForce false;
      generic-extlinux-compatible.enable = lib.mkForce false;
    })
    (lib.mkIf (!useUEFI) {
      generic-extlinux-compatible.enable = true;
      grub.enable = false;
    })
  ];

  networking.hostName = hostname;
  networking.useNetworkd = true;
  systemd.network.enable = true;
  systemd.network.networks."10-ethernet" = {
    matchConfig.Type = "ether";
    networkConfig = {
      DHCP = "yes";
      IPv6AcceptRA = true;
    };
  };
  networking.firewall.enable = true;
  networking.firewall.allowedTCPPorts = [ 22 ];

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  users.mutableUsers = false;
  users.users.${username} = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    shell = pkgs.fish;
    openssh.authorizedKeys.keys = sshPublicKeys;
  };

  security.sudo.wheelNeedsPassword = false;

  programs.fish.enable = true;

  environment.systemPackages = with pkgs; [
    # Basic tools
    fish
    vim
    neovim
    git
    htop
    tmux
    tree
    unzip
    wget
    curl
    ripgrep
    fd
    bat

    # Basic development packages
    gcc
    gnumake
    pkg-config
    python3
  ];

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
    "auto-allocate-uids"
    "cgroups"
    "lix-custom-sub-commands"
    "pipe-operator"
  ];
  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.allowBroken = false;
  nixpkgs.config.permittedInsecurePackages = [ ];
  nixpkgs.config.allowUnsupportedSystem = false;
  nixpkgs.config.allowAliases = false;
  time.timeZone = "UTC";
  i18n.defaultLocale = "en_US.UTF-8";
  zramSwap.enable = true;
  hardware.enableRedistributableFirmware = true;
  system.stateVersion = "26.05";

  nix.settings.substituters = [ "https://nix-community.cachix.org" ];
  nix.settings.trusted-public-keys = [
    "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
  ];
  nix.packages = pkgs.lixPackageSets.stable.lix;
  nix.gc.automatic = true;
  nix.gc.options = "--delete-older-than 3d";
  nix.channel.enable = false;
  nix.settings.require-sigs = true;
  nix.settings.auto-optimise-store = true;
  nix.settings.min-free = 5 * 1024 * 1024 * 1024;
  nix.settings.max-free = 20 * 1024 * 1024 * 1024;
  nix.settings.allowed-users = [ "@wheel" ];
  nix.settings.trusted-users = [ "@wheel" ];
  nix.settings.use-registries = true;
  nix.settings.flake-registry = "";
  nix.settings.max-jobs = "auto";
  nix.settings.sandbox = true;
  nix.settings.system-features = [ "nixos-test" "big-parallel" "kvm" "recursive-nix" "uid-range" ];
  nix.settings.keep-going = true;
  nix.settings.log-lines = 30;
  nix.settings.warn-dirty = false;
  nix.settings.http-connections = 50;
  nix.settings.accept-flake-config = false;
  nix.settings.allow-import-from-derivation = true;
  nix.settings.keep-derivations = true;
  nix.settings.keep-outputs = true;
  nix.settings.use-xdg-base-directories = true;
}
