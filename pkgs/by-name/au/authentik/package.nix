{
  lib,
  applyPatches,
  bash,
  buildGo127Module,
  fetchFromGitHub,
  go_1_27,
  newScope,
  nodejs_26,
  pnpm_12,
  python314,
}:
# Use makeScope to allow overriding the attributes of all dependencies.
#
# Example overlays:
#
# ```
# (final: prev: {
#   authentik = prev.authentik.overrideScope (finalScope: prevScope: {
#     core = prevScope.core.overrideAttrs { ... };
#   });
# })
# ```
#
# ```
# (final: prev: {
#   authentik = prev.authentik.appendPythonDependencies (ps: [ps.pillow]);
# })
# ```
(lib.makeScope newScope (
  scope:
  let
    source = lib.fromJSON (lib.readFile ./source.json);

    inherit (scope) callPackage;

    # Create a builder from a set of extensions (overlays) and a builder function.
    # Depending on the type of `userFnOrAttrs` the builder function is either invoked with:
    # - function: a fixed point function with the extensions applied
    # - set: an attribute set resulting from applying the extensions to the given set
    mkPackageBuilder =
      exts: builderFn: userFnOrAttrs:
      let
        userFn = if lib.isFunction userFnOrAttrs then userFnOrAttrs else _: userFnOrAttrs;
        extended = lib.extends (lib.composeManyExtensions exts) userFn;
        args = if lib.isFunction userFnOrAttrs then extended else (lib.fix extended);
      in
      builderFn args;

    # Set some meta defaults
    defaultsLayer = finalAttrs: prevAttrs: {
      version = prevAttrs.version or scope.version;
      pos = prevAttrs.pos or builtins.unsafeGetAttrPos "pname" prevAttrs;
      meta = prevAttrs.meta or { } // {
        description = prevAttrs.meta.description or "Authentication glue you need";
        changelog =
          prevAttrs.meta.changelog
            or "https://github.com/goauthentik/authentik/releases/tag/version%2F${finalAttrs.version}";
        homepage = prevAttrs.meta.homepage or "https://goauthentik.io/";
        license = prevAttrs.meta.license or lib.licenses.mit;
        platforms =
          prevAttrs.meta.platforms or [
            "aarch64-linux"
            "x86_64-linux"
          ];
        maintainers =
          prevAttrs.meta.maintainers or (with lib.maintainers; [
            jvanbruegge
            risson
          ]);
      };
    };

    # Apply the final source tree and sourceRoot
    sourceLayer =
      finalAttrs: prevAttrs:
      let
        src = prevAttrs.src or scope.patchedSrc;
      in
      {
        inherit src;
        sourceRoot =
          if prevAttrs ? sourceDir then "${src.name}/${prevAttrs.sourceDir}" else prevAttrs.sourceRoot or "";
        sourceDir = null;
      };

    # Replace the bundled API clients with source build ones.
    withClientsLayer =
      finalAttrs: prevAttrs:
      {
        postUnpack =
          let
            packages = "${finalAttrs.src.name}/packages";
            webPackages = "${finalAttrs.src.name}/web/packages";
          in
          (prevAttrs.postUnpack or "")
          + ''
            if [ -n "''${outputHash-}" ]; then
              echo "Error: The 'withClientsLayer' postUnpack hook is not allowed to be run in a FOD."
              echo "Any change in a 'client-*' build output could invalidate the produced hash."
              echo
              echo "Update 'withClientsLayer' to skip the postUnpack hook in the FOD."
              exit 1
            fi

            chmod u+w ${packages}
            chmod -R u+w ${packages}/client-{go,rust,ts}
            rm -rf ${packages}/client-{go,rust,ts}
            cp -r ${scope.client-go} ${packages}/client-go
            cp -r ${scope.client-rust} ${packages}/client-rust
            cp -r ${scope.client-ts} ${packages}/client-ts

            chmod u+w ${webPackages}
            chmod -R u+w ${webPackages}/client-ts
            rm -rf ${webPackages}/client-ts
            cp -r ${scope.client-ts} ${webPackages}/client-ts
          '';
      }
      # Avoid fetchCargoVendor picking up postUnpack, so hash generation is independent from the clients
      // lib.optionalAttrs (prevAttrs ? cargoHash) {
        depsExtraArgs = prevAttrs.depsExtraArgs or { } // {
          # Keep any previously set hook (without our modifications) or clear the field
          postUnpack = prevAttrs.depsExtraArgs.postUnpack or prevAttrs.postUnpack or null;
        };
      };

    # Apply defaults shared by all Go outposts
    goOutpostLayer = finalAttrs: prevAttrs: {
      outpostName = null;
      pos = builtins.unsafeGetAttrPos "outpostName" prevAttrs;
      pname = "authentik-${prevAttrs.outpostName}-outpost";
      inherit (scope.server) vendorHash;
      env.CGO_ENABLED = 0;
      subPackages = [ "cmd/${prevAttrs.outpostName}" ];

      meta = prevAttrs.meta or { } // {
        homepage = "https://goauthentik.io/docs/providers/${prevAttrs.outpostName}/";
        mainProgram = prevAttrs.meta.mainProgram or prevAttrs.outpostName;
      };
    };
  in
  {
    mkComponent = mkPackageBuilder [
      defaultsLayer
      sourceLayer
    ];

    mkComponentWithClients = mkPackageBuilder [
      defaultsLayer
      sourceLayer
      withClientsLayer
    ];

    mkGoOutpost = mkPackageBuilder [
      defaultsLayer
      sourceLayer
      withClientsLayer
      goOutpostLayer
    ];

    # Alias fixed version requirements, so all components can use the unnumbered names
    buildGoModule = buildGo127Module;
    go = go_1_27;
    nodejs = nodejs_26;
    pnpm = pnpm_12;

    inherit (source.authentik) version;

    src = fetchFromGitHub {
      owner = "goauthentik";
      repo = "authentik";
      tag = "version/${source.authentik.version}";
      hash = source.authentik.hash;
    };

    patches = [ ];

    # Add additional patches to apply to the authentik source tree.
    appendPatches =
      patches:
      scope.overrideScope (
        finalScope: prevScope: {
          patches = prevScope.patches ++ patches;
        }
      );

    patchedSrc =
      if scope.patches == [ ] then
        scope.src
      else
        applyPatches {
          name = "${scope.src.name or "authentik-source"}-patched";
          inherit (scope) src patches;
        };

    extraPythonDependencies = [ ];

    # Add additional python dependencies to the authentik environment.
    # This makes them available during policy evaluation.
    appendPythonDependencies =
      dependenciesFn:
      scope.overrideScope (
        finalScope: prevScope: {
          extraPythonDependencies =
            prevScope.extraPythonDependencies ++ dependenciesFn finalScope.python.pkgs;
        }
      );

    client-go = callPackage (
      {
        go,
        mkComponent,
        openapi-generator-cli,
        python,
        stdenvNoCC,
      }:
      mkComponent stdenvNoCC.mkDerivation {
        pname = "authentik-client-go";
        sourceDir = "packages/client-go";

        nativeBuildInputs = [
          openapi-generator-cli
          go
          (python.withPackages (ps: [ ps.pyyaml ]))
        ];

        buildPhase = ''
          runHook preBuild

          python ../../scripts/api_filter_schema.py ../../schema.yml schema.yml operation_ids
          openapi-generator-cli generate \
            -i schema.yml -o $out \
            -g go \
            -c config.yaml

          cd $out
          rm -r .gitignore .openapi-generator .openapi-generator-ignore .travis.yml README.md api git_push.sh go.mod go.sum
          gofmt -w .

          runHook postBuild
        '';
      }
    ) { };

    client-rust = callPackage (
      {
        mkComponent,
        openapi-generator-cli,
        python,
        stdenvNoCC,
      }:
      mkComponent stdenvNoCC.mkDerivation (finalAttrs: {
        pname = "authentik-client-rust";
        sourceDir = "packages/client-rust";

        nativeBuildInputs = [
          openapi-generator-cli
          (python.withPackages (ps: [ ps.pyyaml ]))
        ];

        buildPhase = ''
          runHook preBuild

          mkdir $out
          cp .openapi-generator-ignore Cargo.toml $out

          python ../../scripts/api_filter_schema.py ../../schema.yml schema.yml operation_ids
          openapi-generator-cli generate \
            -i schema.yml -o $out \
            -g rust \
            -c config.yaml \
            --additional-properties=packageVersion=${finalAttrs.version}

          cd $out
          sed -i 's/models::models::/models::/g' src/apis/*
          rm -rf .gitignore .openapi-generator .travis.yml README.md api/openapi.yaml git_push.sh schema.yml

          runHook postBuild
        '';
      })
    ) { };

    client-ts = callPackage (
      {
        mkComponent,
        nodejs,
        openapi-generator-cli,
        stdenvNoCC,
        typescript,
      }:
      mkComponent stdenvNoCC.mkDerivation (finalAttrs: {
        pname = "authentik-client-ts";
        sourceDir = "packages/client-ts";

        postPatch = ''
          substituteInPlace config.yaml \
            --replace-fail '/local' "$(pwd)"
        '';

        nativeBuildInputs = [
          nodejs
          openapi-generator-cli
          typescript
        ];

        buildPhase = ''
          runHook preBuild

          openapi-generator-cli generate \
            -i ../../schema.yml -o $out \
            -g typescript-fetch \
            -c config.yaml \
            --additional-properties=npmVersion=${finalAttrs.version} \
            --git-repo-id authentik --git-user-id goauthentik

          cd $out
          rm -r .npmignore .openapi-generator .openapi-generator-ignore README.md docs
          npm run build

          runHook postBuild
        '';
      })
    ) { };

    webui = callPackage (
      {
        chromedriver,
        fetchPnpmDeps,
        mkComponent,
        mkComponentWithClients,
        nodejs,
        pnpmConfigHook,
        pnpm,
        stdenvNoCC,
      }:
      mkComponentWithClients stdenvNoCC.mkDerivation (finalAttrs: {
        pname = "authentik-webui";
        sourceDir = "web";

        postPatch = ''
          substituteInPlace packages/core/version/node.js \
            --replace-fail 'const prerelease = ' 'const prerelease = false; // ' \
            --replace-fail 'import PackageJSON from "../../../../package.json" with { type: "json" };' "" \
            --replace-fail '(PackageJSON.version);' '"${finalAttrs.version}";'
        '';

        nativeBuildInputs = [
          nodejs
          pnpmConfigHook
          pnpm
        ];

        pnpmDeps = mkComponent fetchPnpmDeps {
          inherit (finalAttrs) pname sourceRoot;
          inherit pnpm;
          fetcherVersion = 4;
          hash = source.webuiPnpmHash;
        };

        buildPhase = ''
          runHook preBuild

          pnpm run build
          pnpm run build:sfe

          runHook postBuild
        '';

        env.CHROMEDRIVER_FILEPATH = lib.getExe chromedriver;
        env.NODE_ENV = "production";

        installPhase = ''
          runHook preInstall
          mkdir $out
          cp -r dist $out/dist
          cp -r authentik $out/authentik
          runHook postInstall
        '';
      })
    ) { };

    # Extract the default blueprints, so they can be customized easily. This can be done by:
    # - using `overrideScope`, which causes some rebuilds
    # - setting the `AUTHENTIK_BLUEPRINTS_DIR` variable for the worker service
    #
    # 'additionalPaths` are copied with symlinks resolved, because they can cause issues at runtime.
    blueprints = callPackage (
      {
        mkComponent,
        rsync,
        stdenvNoCC,
        # additional directories to copy into the output
        additionalPaths ? [ ],
      }:
      mkComponent stdenvNoCC.mkDerivation {
        pname = "authentik-blueprints";

        dontBuild = true;

        installPhase = ''
          runHook preInstall

          cp -rL blueprints $out

          ${lib.concatMapStrings (p: ''
            echo "Copying blueprints from ${p}"
            ${lib.getExe rsync} -rL --info=name ${p}/ $out/
          '') additionalPaths}

          runHook postInstall
        '';
      }
    ) { };

    python = python314.override {
      self = scope.python;

      packageOverrides = final: prev: {
        django = final.django_5;

        ak-guardian = scope.mkComponent final.buildPythonPackage {
          pname = "ak-guardian";
          version = "3.2.0";
          sourceDir = "packages/ak-guardian";

          pyproject = true;

          build-system = with final; [ hatchling ];

          dependencies = with final; [
            django
            typing-extensions
          ];
        };

        django-channels-postgres = scope.mkComponent final.buildPythonPackage {
          pname = "django-channels-postgres";
          version = "0.1.0";
          sourceDir = "packages/django-channels-postgres";

          pyproject = true;

          build-system = with final; [ hatchling ];

          dependencies =
            with final;
            [
              channels
              django
              django-pgtrigger
              msgpack
              psycopg
              structlog
            ]
            ++ psycopg.optional-dependencies.pool;
        };

        django-dramatiq-postgres = scope.mkComponent final.buildPythonPackage {
          pname = "django-dramatiq-postgres";
          version = "0.1.0";
          sourceDir = "packages/django-dramatiq-postgres";

          pyproject = true;

          build-system = with final; [ hatchling ];

          dependencies = with final; [
            cron-converter
            django
            django-pglock
            django-pgtrigger
            dramatiq
            structlog
            tenacity
          ];
        };

        django-postgres-cache = scope.mkComponent final.buildPythonPackage {
          pname = "django-postgres-cache";
          version = "0.1.0";
          sourceDir = "packages/django-postgres-cache";

          pyproject = true;

          build-system = with final; [ hatchling ];

          dependencies = with final; [
            django
            django-postgres-extra
          ];
        };

        authentik = scope.mkComponent final.buildPythonPackage {
          pname = "authentik";
          pyproject = true;

          postPatch = ''
            substituteInPlace authentik/root/settings.py \
              --replace-fail 'Path(__file__).absolute().parent.parent.parent' "Path(\"$out\")"
            substituteInPlace authentik/lib/default.yml \
              --replace-fail '/blueprints' "${scope.blueprints}"
            substituteInPlace authentik/stages/email/utils.py \
              --replace-fail 'web/' '${scope.webui}/'
            # allways allow file upload if the data directoy exists
            substituteInPlace authentik/admin/files/backends/file.py \
              --replace-fail "and (self._base_dir.is_mount() or (self._base_dir / self.usage.value).is_mount())" ""
          '';

          buildInputs = [ bash ];

          build-system = with final; [ hatchling ];

          pythonRemoveDeps = [ "dumb-init" ];

          pythonRelaxDeps = true;

          dependencies =
            with final;
            [
              ak-guardian
              argon2-cffi
              cachetools
              channels
              cryptography
              dacite
              deepmerge
              defusedxml
              django
              django-channels-postgres
              django-countries
              django-dramatiq-postgres
              django-filter
              django-model-utils
              django-pglock
              django-pgtrigger
              django-postgres-cache
              django-postgres-extra
              django-prometheus
              django-storages
              django-tenants
              djangoql
              djangorestframework
              docker
              drf-spectacular
              duo-client
              fido2
              geoip2
              geopy
              google-api-python-client
              gssapi
              gunicorn
              jsonpatch
              jwcrypto
              kubernetes
              ldap3
              lxml
              msgraph-sdk
              msgspec
              opencontainers
              packaging
              paramiko
              psycopg
              pydantic
              pydantic-scim
              pyjwt
              pyrad
              pyroscope-io
              python-kadmin-rs
              pyyaml
              requests-oauthlib
              scim2-filter-parser
              sentry-sdk
              service-identity
              setproctitle
              structlog
              swagger-spec-validator
              twilio
              ua-parser
              unidecode
              urllib3
              uvicorn
              watchdog
              webauthn
              wsproto
              xmlsec
              zxcvbn
            ]
            ++ django-storages.optional-dependencies.s3
            ++ psycopg.optional-dependencies.c
            ++ psycopg.optional-dependencies.pool
            ++ uvicorn.optional-dependencies.standard;

          postInstall = ''
            mkdir -p $out/web
            cp -r lifecycle manage.py $out/${prev.python.sitePackages}/
            ln -s $out/${prev.python.sitePackages}/authentik $out/authentik
            ln -s $out/${prev.python.sitePackages}/lifecycle $out/lifecycle
            patchShebangs $out/lifecycle/ak
          '';
        };
      };
    };

    # extract gunicorn config so server/core don't have to depend on the python package
    gunicornConfPy = callPackage (
      {
        mkComponent,
        stdenvNoCC,
      }:
      mkComponent stdenvNoCC.mkDerivation {
        name = "gunicorn.conf.py";
        dontBuild = true;
        installPhase = "cp lifecycle/gunicorn.conf.py $out";
      }
    ) { };

    server = callPackage (
      {
        buildGoModule,
        gunicornConfPy,
        mkComponentWithClients,
        webui,
      }:
      mkComponentWithClients buildGoModule {
        pname = "authentik-server";

        postPatch = ''
          substituteInPlace internal/gounicorn/gounicorn.go \
            --replace-fail './lifecycle/gunicorn.conf.py' "${gunicornConfPy}"
          substituteInPlace web/static.go \
            --replace-fail './web' "${webui}"
          substituteInPlace internal/web/static.go \
            --replace-fail './web' "${webui}"
        '';

        env.CGO_ENABLED = 0;

        # calculate the vendorHash without other dependencies, so it is only based on the `go.sum` file
        overrideModAttrs.postPatch = "";

        vendorHash = source.serverVendorHash;

        postInstall = ''
          mv $out/bin/server $out/bin/authentik-server
        '';

        subPackages = [ "cmd/server" ];

        meta.mainProgram = "authentik-server";
      }
    ) { };

    core = callPackage (
      {
        buildMode ? "core",
        aws-lc,
        cacert,
        clangStdenv,
        cmake,
        go,
        gunicornConfPy,
        mkComponentWithClients,
        perl,
        pkg-config,
        python,
        rustPlatform,
        webui,
        zstd,
      }:
      mkComponentWithClients rustPlatform.buildRustPackage (finalAttrs: {
        pname = "authentik-${buildMode}";

        postPatch = lib.optionalString (buildMode == "core") ''
          ln -s ${webui}/dist web/dist

          substituteInPlace src/server/mod.rs \
            --replace-fail './lifecycle/gunicorn.conf.py' "${gunicornConfPy}"
          substituteInPlace src/server/static.rs \
            --replace-fail '"./web' '"${webui}'
        '';

        nativeBuildInputs = [
          cmake
          go
          perl
          pkg-config
        ]
        ++ lib.optionals (buildMode == "core") [
          python
        ];

        buildInputs = [
          aws-lc
          zstd
        ];
        # avoid multiple vendor folders for different "name"s
        cargoDepsName = "authentik-${finalAttrs.version}";
        cargoHash = source.coreCargoHash;

        buildNoDefaultFeatures = true;
        buildFeatures = [ buildMode ];

        env = {
          # See https://github.com/goauthentik/authentik/blob/version/2026.5.0/lifecycle/container/Dockerfile#L155-L156
          # Not using makeRustPlatform with clangStdenv to workaround https://github.com/NixOS/nixpkgs/issues/303796
          AWS_LC_FIPS_SYS_HOST_CC = "${clangStdenv.cc}/bin/${clangStdenv.cc.targetPrefix}cc";
          AWS_LC_FIPS_SYS_HOST_CXX = "${clangStdenv.cc}/bin/${clangStdenv.cc.targetPrefix}c++";

          RUSTFLAGS = "--cfg tokio_unstable";
        };

        nativeCheckInputs = [ cacert ];

        checkFlags = [
          # requieres db with migrations applied
          "--skip=outpost::proxy::session::postgres::tests::save_load_expire_logout"
        ];

        meta = {
          mainProgram = "authentik";
        }
        // lib.optionalAttrs (buildMode == "proxy") {
          description = "Authentik proxy outpost which is used for HTTP reverse proxy authentication";
          homepage = "https://goauthentik.io/docs/providers/proxy/";
        };
      })
    ) { };

    authentik = callPackage (
      {
        core,
        extraPythonDependencies,
        makeBinaryWrapper,
        mkComponent,
        outposts,
        python,
        server,
        stdenvNoCC,
      }:
      mkComponent stdenvNoCC.mkDerivation {
        pname = "authentik";

        src = null;

        nativeBuildInputs = [ makeBinaryWrapper ];

        buildCommand = ''
          mkdir -p $out/bin
          makeWrapper ${python.pkgs.authentik}/lifecycle/ak $out/bin/ak \
            --prefix PATH : ${
              lib.makeBinPath [
                (python.withPackages (ps: [ ps.authentik ] ++ extraPythonDependencies))
                core
                server
              ]
            } \
            --set TMPDIR /dev/shm \
            --set PYTHONDONTWRITEBYTECODE 1 \
            --set PYTHONUNBUFFERED 1
        '';

        passthru.components = scope;
        passthru.outposts = outposts;
        passthru.tests.updateScript-lint = callPackage (
          {
            runCommand,
            python,
          }:
          runCommand "authentik-updateScript-lint"
            {
              buildInputs = [
                (python.withPackages (ps: [
                  ps.packaging
                  ps.pydantic
                  ps.ruff
                  ps.stackprinter
                  ps.ty
                  ps.types-requests
                ]))
              ];
            }
            ''
              echo "# run ty"
              ty check --error-on-warning ${./update.py}
              echo "# run ruff check"
              ruff check --ignore=EXE005 ${./update.py}
              echo "# run ruff format"
              ruff format --check --diff ${./update.py}

              touch $out
            ''
        ) { };
        passthru.updateScript = ./update.py;

        meta.mainProgram = "ak";
      }
      // {
        overrideScope = f: (scope.overrideScope f).authentik;

        appendPatches = patches: (scope.appendPatches patches).authentik;

        appendPythonDependencies =
          dependenciesFn: (scope.appendPythonDependencies dependenciesFn).authentik;
      }
    ) { };

    outposts = {
      ldap = callPackage ./ldap.nix { };
      proxy = callPackage ./proxy.nix { };
      radius = callPackage ./radius.nix { };
    };
  }
)).authentik
