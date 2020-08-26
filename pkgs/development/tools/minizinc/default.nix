{ stdenv
, lib
, config
, fetchFromGitHub
, fetchpatch
, cmake
, flex
, bison
, enableCbcSolver ? true
, cbc
, zlib
, enableGecodeSolver ? true
, writeText
, gecode
, mpfr
, enableGurobiSolver ? config.allowUnfree or false
, autoPatchelfHook
, gurobi
}:

assert enableCbcSolver -> cbc != null && zlib != null;
assert enableGecodeSolver -> gecode != null && mpfr != null;
assert enableGurobiSolver -> gurobi != null;
let
  version = "2.4.3";

  gecodeConfig = writeText "gecode.msc" (builtins.toJSON {
    id = "org.gecode.gecode";
    name = "Gecode";
    description = "Gecode FlatZinc executable";
    version = gecode.version;
    mznlib = "${gecode}/share/gecode/mznlib";
    executable = "${gecode}/bin/fzn-gecode";
    tags = [ "cp" "int" "float" "set" "restart" ];
    stdFlags = [ "-a" "-f" "-n" "-p" "-r" "-s" "-t" ];
    supportsMzn = false;
    supportsFzn = true;
    needsSolns2Out = true;
    needsMznExecutable = false;
    needsStdlibDir = false;
    isGUIApplication = false;
  });

  testModel = writeText "model.mzn" ''
    var 1..3: x;
    var 1..3: y;
    constraint x+y > 4;
    constraint x < y;
    solve satisfy;
  '';

in
stdenv.mkDerivation {
  pname = "minizinc";
  inherit version;

  nativeBuildInputs = lib.optionals enableGurobiSolver [ autoPatchelfHook ];

  buildInputs = [ cmake flex bison ]
    ++ lib.optionals enableCbcSolver [ cbc zlib ]
    ++ lib.optionals enableGecodeSolver [ gecode mpfr ]
    ++ lib.optionals enableGurobiSolver [ gurobi ];

  runtimeDependencies = lib.optionals enableGurobiSolver [ gurobi ];

  src = fetchFromGitHub {
    owner = "MiniZinc";
    repo = "libminizinc";
    rev = version;
    sha256 = "0mahf621zwwywimly5nd6j39j7qr48k5p7zwpfqnjq4wn010mbf8";
  };

  patches = [
    # Fix build with newer Bison versions:
    # https://github.com/MiniZinc/libminizinc/issues/389
    (fetchpatch {
      url = "https://github.com/MiniZinc/libminizinc/commit/d3136f6f198d3081943c17ac6890dbe14a81d112.diff";
      sha256 = "1f4wxn9422ndgq6dd0vqdxm2313srm7gn9nh82aas2xijdxlmz2c";
    })
    (fetchpatch {
      url = "https://github.com/MiniZinc/libminizinc/commit/8d4dcf302e78231f7c2665150e8178cacd06f91c.diff";
      sha256 = "1wgciyrqijv7b4wqha94is5skji8j7b9wq6fkdsnsimfd3xpxhqw";
    })
    (fetchpatch {
      url = "https://github.com/MiniZinc/libminizinc/commit/952ffda0bd23dc21f83d3e3f080ea5b3a414e8e0.diff";
      sha256 = "0cnsfqw0hwm7rmazqnb99725rm2vdwab75vdpr5x5l3kjwsn76rj";
    })
  ];

  postInstall = lib.optionalString enableGecodeSolver ''
    mkdir -p $out/share/minizinc/solvers
    ln -s ${gecodeConfig} $out/share/minizinc/solvers/gecode.msc
  '';

  doInstallCheck = enableCbcSolver || enableGecodeSolver;
  installCheckPhase = let check = enable: solver: lib.optionalString enable ''
    echo 'checking ${solver} solver'
    $out/bin/minizinc --solver ${solver} ${testModel}
  ''; in
    check enableCbcSolver "org.minizinc.mip.coin-bc" +
    check enableGecodeSolver "org.gecode.gecode";

  meta = with lib; {
    homepage = "https://www.minizinc.org/";
    description = "MiniZinc is a medium-level constraint modelling language.";

    longDescription = ''
      MiniZinc is a medium-level constraint modelling
      language. It is high-level enough to express most
      constraint problems easily, but low-level enough
      that it can be mapped onto existing solvers easily and consistently.
      It is a subset of the higher-level language Zinc.
    '';

    license = licenses.mpl20;
    platforms = platforms.linux;
    maintainers = [ maintainers.sheenobu ];
  };
}
