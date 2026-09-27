{ lib, self, ... }:

{
  system.activationScripts.embedNixosFlake = lib.stringAfter [ "users" "groups" ] ''
    mkdir -p /root/nixos-config
    if [ -z "$(ls -A /root/nixos-config 2>/dev/null)" ]; then
      echo "embed-flake: copying flake source into /root/nixos-config"
      cp -r --no-preserve=mode,ownership ${self}/. /root/nixos-config/
      chmod -R u+rwX,go-rwx /root/nixos-config
    fi
  '';
}
