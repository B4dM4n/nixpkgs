import ./make-test-python.nix (
  {
    pkgs,
    lib,
    ...
  }: {
    name = "authentik";

    nodes = {
      server = {pkgs, ...}: {
        virtualisation.cores = 2;
        virtualisation.memorySize = 2048;

        services.authentik = {
          enable = true;
          settings = {
            AUTHENTIK_SECRET_KEY = "abcdefghijklmnopqrstuvwxyz0123456789";
          };
        };
      };
    };
    testScript = ''
      start_all()

      server.wait_for_unit("authentik-server.service")
      server.wait_for_unit("authentik-worker.service")
      server.wait_for_open_port(9000)
      server.wait_until_succeeds(
          "curl --fail 'http://127.0.0.1:9000/if/flow/initial-setup/' | grep -q -v 'failed to connect to authentik backend'"
      )
    '';
  }
)
