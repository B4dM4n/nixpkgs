{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.authentik;

  settingsFormat = pkgs.formats.keyValue {};
in {
  ###### interface
  options = {
    services.authentik = {
      enable = lib.mkEnableOption "authentik";

      postgres = {
        configure = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = ''
            Configure a local postgres server and database.

            This will also configure authentik to use the local postgres server.
          '';
        };

        database = lib.mkOption {
          type = lib.types.str;
          default = "authentik";
          description = ''
            The local postgres database name to use.

            This will create the database user and database and configure authentik to use them.
          '';
        };
      };

      redis = {
        configure = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Configure a local Redis server instance.";
        };

        port = lib.mkOption {
          type = lib.types.port;
          default = 6381;
          description = "Port for the Redis server.";
        };

        passwordFile = lib.mkOption {
          type = lib.types.nullOr lib.types.path;
          default = null;
          example = "/run/keys/redis-password";
          description = ''
            A file containing the password for the Redis server.
          '';
        };
      };

      package = lib.mkPackageOption pkgs "authentik" {};

      settings = lib.mkOption {
        description = ''
          Config options for the services.

          https://docs.goauthentik.io/docs/installation/configuration
        '';
        type = lib.types.submodule {
          freeformType = settingsFormat.type;
        };
        default = {
          AUTHENTIK_STORAGE__MEDIA__BACKEND = "file";
          AUTHENTIK_STORAGE__MEDIA__FILE__PATH = "/var/lib/authentik/media";
        };
      };
    };
  };

  ###### implementation
  config = lib.mkIf cfg.enable {
    users.groups.authentik = {
      gid = config.ids.gids.authentik;
    };

    users.users.authentik = {
      description = "Authentik";
      group = "authentik";
      createHome = true;
      home = "/var/lib/authentik";
      uid = config.ids.uids.authentik;
    };

    systemd.services = let
      mkService = mode: {
        description = "Authentik ${mode}";
        after = ["network.target"];
        wantedBy = ["multi-user.target"];

        serviceConfig = {
          ExecStart = ["${cfg.package}/bin/ak ${mode}"];
          Restart = "on-failure";
          User = "authentik";
          StateDirectory = "authentik";
          EnvironmentFile = settingsFormat.generate "authentik.env" (cfg.settings
            // lib.optionalAttrs cfg.postgres.configure {
              AUTHENTIK_POSTGRESQL__HOST = "/run/postgresql";
              AUTHENTIK_POSTGRESQL__NAME = "authentik";
            }
            // lib.optionalAttrs cfg.redis.configure {
              AUTHENTIK_REDIS__HOST = "localhost";
              AUTHENTIK_REDIS__PORT = toString cfg.redis.port;
            }
            // lib.optionalAttrs (cfg.redis.configure && cfg.redis.passwordFile != null) {
              AUTHENTIK_REDIS__PASSWORD = "file://${cfg.redis.passwordFile}";
            });

          CapabilityBoundingSet = [""];
          LockPersonality = true;
          MemoryDenyWriteExecute = true;
          NoNewPrivileges = true;
          PrivateDevices = true;
          PrivateTmp = true;
          PrivateUsers = true;
          ProcSubset = "pid";
          ProtectClock = true;
          ProtectControlGroups = true;
          ProtectHome = true;
          ProtectHostname = true;
          ProtectKernelLogs = true;
          ProtectKernelModules = true;
          ProtectKernelTunables = true;
          ProtectProc = "invisible";
          ProtectSystem = "strict";
          RemoveIPC = true;
          RestrictAddressFamilies = ["AF_INET" "AF_INET6" "AF_UNIX"];
          RestrictNamespaces = true;
          RestrictRealtime = true;
          RestrictSUIDSGID = true;
          SystemCallArchitectures = "native";
          SystemCallFilter = ["@system-service" "~@memlock" "~@privileged" "~@setuid" "~@timer" "chown"];
          UMask = "0077";
        };
      };
    in {
      authentik-server = mkService "server";
      authentik-worker = mkService "worker";
    };

    services.redis.servers.authentik = lib.mkIf cfg.redis.configure {
      enable = true;
      port = cfg.redis.port;
      requirePassFile = lib.mkIf (cfg.redis.passwordFile != null) cfg.redis.passwordFile;
    };

    services.postgresql = lib.mkIf cfg.postgres.configure {
      enable = true;
      ensureUsers = [
        {
          name = "authentik";
          ensureDBOwnership = true;
        }
      ];
      ensureDatabases = ["authentik"];
    };
  };
}
