{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.services.prometheus.exporters.smokeping;
in
{
  port = 9374;

  extraOpts = with types; {
    hosts = mkOption {
      type = nonEmptyListOf str;
      description = ''
        A list of hosts to probe.

        To load a list of hosts from a file you can create a Systemd environment file containing
        a <literal>HOSTS=...</literal> line and use a configuration like this:
        <programlisting>
        services.prometheus.exporters.smokeping.hosts = [ "$HOSTS" ];
        systemd.services.prometheus-smokeping-exporter.serviceConfig.EnvironmentFile = [
          "/etc/smokeping_hosts"
        ];
        </programlisting>
      '';
    };
    telemetry-path = mkOption {
      type = str;
      default = "/metrics";
      description = "Path under which to expose metrics.";
    };
    buckets = mkOption {
      type = str;
      default = let gen = l: if length l < 20 then gen (l ++ [ (last l * 2) ]) else l; in
        concatMapStringsSep "," toString (gen [ 0.00005 ]);
      description = "A comma separated list of histogram buckets.";
    };
    ping-interval = mkOption {
      type = str;
      default = "1s";
      description = "Ping interval duration.";
    };
    log-level = mkOption {
      type = enum [ "debug" "info" "warn" "error" "fatal" ];
      default = "info";
      description = "Only log messages with the given severity or above.";
    };
    privileged = mkOption {
      type = bool;
      default = true;
      description = "Run in privileged ICMP mode.";
    };
    pkg = mkOption {
      type = package;
      default = pkgs.smokeping_prober;
      description = "The smokeping_prober package.";
    };
  };

  serviceOpts = {
    serviceConfig = rec {
      ExecStart =
        let args = with cfg; [
          "--web.listen-address=${listenAddress}:${toString port}"
          "--web.telemetry-path=${telemetry-path}"
          "--buckets=${buckets}"
          "--ping.interval=${ping-interval}"
          "--${optionalString (!privileged) "no-"}privileged"
          "--log.level=${log-level}"
        ] ++ extraFlags ++ hosts; in
        ''
          ${cfg.pkg}/bin/smokeping_prober \
            ${concatStringsSep " \\\n  " args}
        '';

      # CAP_NET_RAW is only needed for ICMP ping
      AmbientCapabilities = optionalString cfg.privileged "CAP_NET_RAW";
      CapabilityBoundingSet = AmbientCapabilities;
      DevicePolicy = "closed";
      LockPersonality = true;
      MemoryDenyWriteExecute = true;
      NoNewPrivileges = true;
      PrivateDevices = true;
      ProtectClock = true;
      ProtectControlGroups = true;
      ProtectHome = true;
      ProtectHostname = true;
      ProtectKernelLogs = true;
      ProtectKernelModules = true;
      ProtectKernelTunables = true;
      ProtectSystem = "strict";
      RestrictAddressFamilies = "AF_INET AF_INET6";
      RestrictNamespaces = true;
      RestrictRealtime = true;
    };
  };
}
