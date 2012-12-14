{ config, pkgs, ... }:

with pkgs.lib;

{

  ###### interface

  options = {

    deployment.virtualbox.memorySize = mkOption {
      default = 512;
      type = types.int;
      description = ''
        Memory size (M) of virtual machine.
      '';
    };

    deployment.virtualbox.headless = mkOption {
      default = false;
      description = ''
        If set, the VirtualBox instance is started in headless mode,
        i.e., without a visible display on the host's desktop.
      '';
    };

    deployment.virtualbox.disks = mkOption {
      default = {};
      example =
        { big-disk = {
            port = 1;
            size = 1048576;
          };
        };
      type = types.attrsOf types.optionSet;
      description = "Definition of the virtual disks attached to this instance.";

      options = {

        port = mkOption {
          example = 1;
          type = types.uniq types.int;
          description = "SATA port number to which the disk is attached.";
        };

        size = mkOption {
          type = types.uniq types.int;
          description = "Size (in megabytes) of this disk.";
        };

        baseImage = mkOption {
          default = null;
          example = "/home/alice/base-disk.vdi";
          type = types.nullOr types.path;
          description = ''
            If set, this disk is created as a clone of the specified
            disk image (and the <literal>size</literal> attribute is
            ignored).
          '';
        };

      };
    };

  };


  ###### implementation

  config = mkIf (config.deployment.targetEnv == "virtualbox") {

    nixpkgs.system = mkOverride 900 "x86_64-linux";

    deployment.virtualbox.disks.disk1 =
      { port = 0;
        size = 0;
        baseImage = mkDefault (
          let
            unpack = name: sha256: pkgs.runCommand "virtualbox-charon-${name}.vdi" {}
              ''
                xz -d < ${pkgs.fetchurl {
                  url = "http://nixos.org/releases/nixos/virtualbox-charon-images/virtualbox-charon-${name}.vdi.xz";
                  inherit sha256;
                }} > $out
              '';
          in if config.nixpkgs.system == "x86_64-linux" then
            unpack "0.1pre3755_fd9604b-3c948a1" "58a8fdcaea605fbcc3decfe075c88caac7bc71d39c5b2b6969849898fb257d81"
          else
            throw "Unsupported VirtualBox system type!"
        );
      };
  };

}
