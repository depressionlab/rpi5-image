{ config, lib, pkgs, ... }:

let
  cfg = config.services.uctronicsDisplay;
in
{
  options.services.uctronicsDisplay = {
    enable = lib.mkEnableOption "the UCTRONICS RM0004 NVMe-hat status display service";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.callPackage ../pkgs/uctronics-display.nix { };
      defaultText = lib.literalExpression "pkgs.callPackage ../pkgs/uctronics-display.nix { }";
      description = "The uctronics-display package (built from UCTRONICS/SKU_RM0004) to run.";
    };

    board = lib.mkOption {
      type = lib.types.enum [
        "pi4"
        "pi5"
      ];
      default = "pi5";
      description = ''
        Which Raspberry Pi family this is running on. Only affects which
        `gpio-shutdown` overlay parameters get written (the hat's power
        button is wired slightly differently on Pi 4 vs Pi 5).
      '';
    };

    enableShutdownButton = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Enable the hat's physical power/shutdown button by loading the
        `gpio-shutdown` overlay on GPIO 4, active-low, matching upstream's
        `deployment_service.sh` defaults. Disable this if you don't use
        the button, or if GPIO 4 is wired to something else on your setup.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    # I2C: the display and its onboard microcontroller are driven
    # entirely over /dev/i2c-1 (see hardware/st7735/st7735.c upstream)
    hardware.i2c.enable = true;
    hardware.raspberry-pi.configtxt.settings.all.dtparam = [
      "i2c_arm=on,i2c_arm_baudrate=400000"
    ];

    # Optional physical shutdown button (GPIO 4)
    hardware.raspberry-pi.configtxt.settings.${cfg.board}.dtoverlay =
      lib.mkIf cfg.enableShutdownButton (
        if cfg.board == "pi5" then
          [ "gpio-shutdown,gpio_pin=4,active_low=1,gpio_pull=up,debounce=1000" ]
        else
          [ "gpio-shutdown,gpio_pin=4,active_low=1,gpio_pull=up" ]
      );

    environment.systemPackages = [ cfg.package ];

    systemd.services.uctronics-display = {
      description = "UCTRONICS RM0004 NVMe-hat status display";
      after = [
        "multi-user.target"
        "systemd-udev-settle.service"
      ];
      wants = [ "systemd-udev-settle.service" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        ExecStart = lib.getExe cfg.package;
        Restart = "always";
        RestartSec = "5s";
        DynamicUser = true;
        SupplementaryGroups = [ "i2c" ];
        PrivateTmp = true;
      };
    };
  };
}
